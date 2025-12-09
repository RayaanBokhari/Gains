# Gains App Scalability Plan

> **Current Status:** Firebase-only architecture, suitable for 0-10K DAU  
> **Last Updated:** December 2024

---

## Table of Contents
1. [Current Architecture](#current-architecture)
2. [Phase 1: 10K-25K Users](#phase-1-10k-25k-users)
3. [Phase 2: 25K-50K Users](#phase-2-25k-50k-users)
4. [Phase 3: 50K-100K Users](#phase-3-50k-100k-users)
5. [Phase 4: 100K+ Users](#phase-4-100k-users)
6. [Cost Projections](#cost-projections)
7. [Implementation Checklist](#implementation-checklist)

---

## Current Architecture

```
┌─────────────────────────────────────┐
│           iOS App (Gains)           │
└──────────────┬──────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼───┐          ┌──────▼──────┐
│Firebase│          │  Firebase   │
│  Auth  │          │  Functions  │
└───┬───┘          └──────┬──────┘
    │                     │
    └──────────┬──────────┘
               │
      ┌────────▼────────┐
      │ Cloud Firestore │
      └─────────────────┘
```

### Current Data Model
```
users/{userId}/
  ├── profile/data
  ├── dailyLogs/{dateId}
  ├── meals/{mealId}
  ├── workouts/{workoutId}
  ├── workoutPlans/{planId}
  ├── dietaryPlans/{planId}
  ├── mealTemplates/{templateId}
  ├── achievements/{achievementId}
  ├── streak/current
  └── conversations/{conversationId}

posts/{postId}  (global collection)
```

### Current Limitations
- No pagination on large collections
- No local caching strategy
- All reads hit Firestore directly
- Single region deployment
- No CDN for images

---

## Phase 1: 10K-25K Users

**Trigger:** Approaching 10K DAU or monthly Firestore bill > $50

### 1.1 Enable Offline Persistence
```swift
// FirestoreService.swift
private init() {
    let settings = FirestoreSettings()
    settings.cacheSettings = PersistentCacheSettings(
        sizeBytes: 100 * 1024 * 1024 // 100MB
    )
    db.settings = settings
}
```

### 1.2 Implement Pagination
Priority collections:
- [ ] Workouts (fetchWorkouts)
- [ ] Community Posts (fetchPosts)
- [ ] Meal history
- [ ] Conversations

```swift
struct PaginatedResult<T> {
    let items: [T]
    let lastDocument: DocumentSnapshot?
    let hasMore: Bool
}

func fetchWorkoutsPaginated(
    userId: String,
    pageSize: Int = 20,
    after: DocumentSnapshot? = nil
) async throws -> PaginatedResult<Workout>
```

### 1.3 Add Composite Indexes
Create `firestore.indexes.json`:
```json
{
  "indexes": [
    {
      "collectionGroup": "meals",
      "fields": [
        {"fieldPath": "date", "order": "ASCENDING"},
        {"fieldPath": "loggedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "workouts",
      "fields": [
        {"fieldPath": "date", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "posts",
      "fields": [
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    }
  ]
}
```

### 1.4 Local Profile Caching
```swift
// Cache profile in UserDefaults/AppStorage
@AppStorage("cachedProfile") private var cachedProfileData: Data?

// Only fetch from Firestore on:
// - App launch (if cache > 1 hour old)
// - Pull to refresh
// - After profile edit
```

### 1.5 Firebase Functions Optimization
```javascript
exports.aiChat = functions.https.onCall({
    memory: '512MiB',
    timeoutSeconds: 60,
    maxInstances: 50,
    minInstances: 1,  // Keep warm
    region: 'us-east4'
}, handler);
```

### Estimated Timeline: 1-2 weeks
### Estimated Cost Impact: -30% on Firestore reads

---

## Phase 2: 25K-50K Users

**Trigger:** 25K DAU or monthly bill > $150

### 2.1 Image CDN Integration
Move from Firebase Storage direct URLs to CDN-optimized delivery.

**Option A: Firebase Extensions**
- Install "Resize Images" extension
- Generates thumbnails automatically

**Option B: Cloudflare Images** (Recommended)
- $5/month for 100K images
- Automatic optimization & resizing
- Global CDN

```swift
// ImageService.swift
func getOptimizedImageURL(_ originalURL: String, width: Int) -> URL {
    // Transform: storage.googleapis.com/... 
    // To: imagedelivery.net/.../w=\(width)
}
```

### 2.2 Denormalize Hot Data
Create summary documents to reduce reads:

```
users/{userId}/
  └── summaries/
      ├── weekly     // Pre-aggregated weekly stats
      ├── monthly    // Pre-aggregated monthly stats
      └── allTime    // Lifetime stats
```

Update via Cloud Functions on write:
```javascript
exports.onMealLogged = functions.firestore
    .document('users/{userId}/meals/{mealId}')
    .onCreate(async (snap, context) => {
        // Update daily, weekly, monthly summaries
    });
```

### 2.3 Batch Writes
```swift
func logMultipleMeals(_ meals: [Food], userId: String) async throws {
    let batch = db.batch()
    
    for meal in meals {
        let ref = db.collection("users/\(userId)/meals").document()
        try batch.setData(from: meal, forDocument: ref)
    }
    
    try await batch.commit()
}
```

### 2.4 Rate Limiting
Add to security rules:
```javascript
function rateLimitCheck() {
    return request.time > resource.data.lastWrite + duration.value(1, 's');
}
```

### 2.5 Split Read/Write Patterns
- Use snapshots for reads (cached)
- Use transactions only for writes that need consistency

### Estimated Timeline: 2-3 weeks
### Estimated Cost Impact: -40% on reads, +$50 for CDN

---

## Phase 3: 50K-100K Users

**Trigger:** 50K DAU or monthly bill > $400

### 3.1 Add Caching Layer (Redis/Upstash)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   iOS App   │────▶│   Redis     │────▶│  Firestore  │
│             │     │   Cache     │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
```

**Upstash Redis** (Serverless, pay-per-request):
- Cache community feed (TTL: 5 min)
- Cache leaderboards (TTL: 1 hour)
- Cache popular meal templates (TTL: 24 hours)

```javascript
// Firebase Function with Redis
const redis = new Redis(process.env.UPSTASH_REDIS_URL);

exports.getCommunityFeed = functions.https.onCall(async (data) => {
    const cached = await redis.get('community:feed');
    if (cached) return JSON.parse(cached);
    
    const posts = await fetchFromFirestore();
    await redis.setex('community:feed', 300, JSON.stringify(posts));
    return posts;
});
```

### 3.2 Implement Real-time Selectively
Only use Firestore listeners for:
- Active workout session
- Today's nutrition (while app is open)
- Chat messages

Remove listeners for:
- Historical data
- Profile views
- Workout history

### 3.3 Multi-Region Deployment
Deploy Firebase Functions to multiple regions:
```javascript
// US users
exports.aiChatUS = functions.region('us-east4').https.onCall(...);

// EU users  
exports.aiChatEU = functions.region('europe-west1').https.onCall(...);
```

Detect region in app:
```swift
let functionRegion = Locale.current.region?.continent == .europe 
    ? "europe-west1" 
    : "us-east4"
```

### 3.4 Background Sync
Move non-critical writes to background:
```swift
// Use BGTaskScheduler for:
// - Syncing offline meals
// - Uploading workout data
// - Refreshing cached data
```

### Estimated Timeline: 4-6 weeks
### Estimated Cost Impact: +$100/month for Redis, -50% Firestore reads

---

## Phase 4: 100K+ Users

**Trigger:** 100K DAU or need for custom features

### 4.1 Hybrid Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      iOS App                             │
└───────────┬─────────────────────────────┬───────────────┘
            │                             │
     ┌──────▼──────┐              ┌───────▼───────┐
     │  Firebase   │              │ Custom API    │
     │    Auth     │              │ (Go/Node)     │
     └──────┬──────┘              └───────┬───────┘
            │                             │
            │                    ┌────────┴────────┐
            │                    │                 │
            │              ┌─────▼─────┐    ┌──────▼──────┐
            │              │ PostgreSQL│    │    Redis    │
            │              │ (Supabase)│    │   (Cache)   │
            │              └───────────┘    └─────────────┘
            │
     ┌──────▼──────┐
     │  Firestore  │ ◀── Keep for: real-time chat, 
     │  (Limited)  │     notifications, presence
     └─────────────┘
```

### 4.2 Database Migration Path
**Keep in Firestore:**
- Real-time features (chat, live workouts)
- User authentication state
- Push notification tokens

**Move to PostgreSQL:**
- User profiles
- Workout history
- Meal logs
- Analytics data

**Supabase** recommended:
- Built-in auth (can sync with Firebase Auth)
- Real-time subscriptions
- Row-level security
- $25/month for 100K MAU

### 4.3 Custom API Server
**Why:**
- Complex queries (aggregations, joins)
- Better cost control
- Custom business logic
- Rate limiting per user

**Stack Recommendation:**
- **Language:** Go or Node.js
- **Hosting:** Railway, Render, or Fly.io
- **Cost:** ~$20-50/month

### 4.4 Analytics Pipeline
```
App Events ──▶ Firebase Analytics ──▶ BigQuery ──▶ Dashboard
                                          │
                                    ┌─────▼─────┐
                                    │  Metabase │
                                    │  or Retool│
                                    └───────────┘
```

### Estimated Timeline: 2-3 months
### Estimated Cost: $200-400/month total

---

## Cost Projections

| DAU | Firestore Reads/day | Functions/day | Est. Monthly Cost |
|-----|--------------------:|---------------:|------------------:|
| 1K | 50K | 5K | $5-10 |
| 5K | 250K | 25K | $25-40 |
| 10K | 500K | 50K | $50-80 |
| 25K | 1M | 125K | $120-180 |
| 50K | 2M | 250K | $250-350 |
| 100K | 4M | 500K | $500-700 |

*With optimizations, costs can be reduced 30-50%*

### Cost Optimization Priority
1. **Pagination** - Reduces reads by 60-80%
2. **Caching** - Reduces reads by 30-40%
3. **Denormalization** - Reduces reads by 20-30%
4. **Image CDN** - Reduces bandwidth costs

---

## Implementation Checklist

### Phase 1 (Do at 10K users)
- [ ] Enable Firestore offline persistence
- [ ] Add pagination to fetchWorkouts()
- [ ] Add pagination to fetchPosts()
- [ ] Create composite indexes
- [ ] Cache user profile locally
- [ ] Add minInstances to AI function
- [ ] Set up Firebase budget alerts
- [ ] Review security rules

### Phase 2 (Do at 25K users)
- [ ] Set up image CDN
- [ ] Create summary documents
- [ ] Implement Cloud Functions for aggregation
- [ ] Add batch write operations
- [ ] Implement rate limiting

### Phase 3 (Do at 50K users)
- [ ] Set up Redis cache (Upstash)
- [ ] Cache community feed
- [ ] Multi-region function deployment
- [ ] Implement background sync
- [ ] Audit real-time listeners

### Phase 4 (Do at 100K users)
- [ ] Evaluate hybrid architecture needs
- [ ] Set up PostgreSQL (Supabase)
- [ ] Build custom API for complex queries
- [ ] Migrate historical data
- [ ] Set up analytics pipeline

---

## Monitoring Checklist

Set up alerts for:
- [ ] Firestore reads > 1M/day
- [ ] Functions errors > 1%
- [ ] API latency p95 > 2s
- [ ] Monthly cost > budget threshold
- [ ] Failed authentication attempts spike

---

## Resources

- [Firebase Pricing Calculator](https://firebase.google.com/pricing)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Upstash Redis](https://upstash.com/)
- [Supabase](https://supabase.com/)
- [Cloudflare Images](https://www.cloudflare.com/products/cloudflare-images/)

---

*This document should be reviewed and updated quarterly or when approaching a new user milestone.*


# Updating Firebase Functions Secret for OpenAI API Key

## Step 1: Update the Secret

Run this command in your terminal (replace `YOUR_NEW_API_KEY` with your actual new API key):

```bash
firebase functions:secrets:set OPENAI_API_KEY
```

This will prompt you to enter the secret value. Paste your new API key when prompted.

**OR** if you want to set it directly:

```bash
echo "YOUR_NEW_API_KEY" | firebase functions:secrets:set OPENAI_API_KEY
```

## Step 2: Verify the Secret

Check that the secret was set correctly:

```bash
firebase functions:secrets:access OPENAI_API_KEY
```

## Step 3: Redeploy Functions

After updating the secret, redeploy your functions so they pick up the new key:

```bash
cd functions
npm run build
firebase deploy --only functions
```

---

## ⚠️ Important: If Switching to o1-mini Model

If you're switching to **`o1-mini`** (OpenAI's new reasoning model), you'll also need to update the code because o1 models have different API requirements:

### Differences:
- **No system messages** - o1 models don't support system role
- **No temperature parameter** - o1 models don't accept temperature
- **No max_tokens** - o1 models control output length automatically
- **Different model name** - Use `"o1-mini"` instead of `"gpt-4o-mini"`

### Code Changes Needed:

Update `functions/src/index.ts` line 118-123:

**Current (gpt-4o-mini):**
```typescript
const response = await client.chat.completions.create({
  model: "gpt-4o-mini",
  messages: openaiMessages,
  temperature: 0.7,
  max_tokens: isStructuredPlanRequest ? 4000 : 1000,
});
```

**For o1-mini:**
```typescript
// Remove system messages (o1 doesn't support them)
const o1Messages = openaiMessages.filter(msg => msg.role !== "system");

const response = await client.chat.completions.create({
  model: "o1-mini",
  messages: o1Messages,
  // No temperature or max_tokens for o1 models
});
```

---

## Quick Reference Commands

```bash
# Set secret (interactive)
firebase functions:secrets:set OPENAI_API_KEY

# View secret (to verify)
firebase functions:secrets:access OPENAI_API_KEY

# List all secrets
firebase functions:secrets:list

# Deploy functions
firebase deploy --only functions

# View function logs (to debug)
firebase functions:log
```

---

## Troubleshooting

If you get errors after updating:

1. **Check secret is set:**
   ```bash
   firebase functions:secrets:access OPENAI_API_KEY
   ```

2. **Check function logs:**
   ```bash
   firebase functions:log --only aiChat
   ```

3. **Verify API key format:**
   - Should start with `sk-`
   - Should be from your OpenAI account
   - Make sure it has access to the model you're using

4. **Test locally (if using emulator):**
   ```bash
   firebase emulators:start --only functions
   ```


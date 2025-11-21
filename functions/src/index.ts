import * as functions from "firebase-functions/v1";
import OpenAI from "openai";

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: string;
}

interface CallableData {
  messages: ChatMessage[];
}

export const aiChat = functions
  .region("us-east4")
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
    secrets: ["OPENAI_API_KEY"],
  })
  .https.onCall(
    async (
      data: CallableData,
      context: functions.https.CallableContext
    ) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "You must be signed in to use the AI coach."
        );
      }

      const messages = data.messages;

      if (!messages || !Array.isArray(messages)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "messages must be an array of { role, content }."
        );
      }

      try {
        const apiKey = process.env.OPENAI_API_KEY;

        console.log("Config check:", {
          hasEnvKey: !!apiKey,
        });

        if (!apiKey) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "OpenAI API key not configured."
          );
        }

        const client = new OpenAI({
          apiKey,
        });

        const response = await client.chat.completions.create({
          model: "gpt-4o-mini",
          messages: messages.map((msg) => ({
            role: msg.role,
            content: msg.content,
          })),
          temperature: 0.7,
        });

        const reply =
          response.choices[0]?.message?.content ??
          "I couldn't generate a response. Try again.";

        return {reply};
      } catch (err: unknown) {
        const errorMessage =
          err instanceof Error ? err.message : "Unknown error";
        console.error("AI error:", errorMessage, err);
        throw new functions.https.HttpsError(
          "internal",
          "AI service failed."
        );
      }
    }
  );

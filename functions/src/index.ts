import * as functions from "firebase-functions/v1";
import OpenAI from "openai";
import {
  ChatCompletionMessageParam,
  ChatCompletionContentPart,
} from "openai/resources/chat/completions";

// Support both text-only and vision messages
type MessageContent = string | Array<{
  type: "text" | "image_url";
  text?: string;
  image_url?: {
    url: string;
  };
}>;

interface ChatMessage {
  role: "system" | "user" | "assistant";
  content: MessageContent;
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

        // Convert messages to proper OpenAI format
        const openaiMessages: ChatCompletionMessageParam[] =
          messages.map((msg) => {
            // Handle different content types properly
            if (typeof msg.content === "string") {
              // Text-only message
              return {
                role: msg.role,
                content: msg.content,
              } as ChatCompletionMessageParam;
            } else {
              // Vision message with array content
              const contentParts: ChatCompletionContentPart[] =
                msg.content.map((part) => {
                  if (part.type === "text" && part.text) {
                    return {
                      type: "text" as const,
                      text: part.text,
                    };
                  } else if (part.type === "image_url" && part.image_url) {
                    return {
                      type: "image_url" as const,
                      image_url: {
                        url: part.image_url.url,
                      },
                    };
                  }
                  throw new Error("Invalid content part");
                });

              return {
                role: msg.role,
                content: contentParts,
              } as ChatCompletionMessageParam;
            }
          });

        // Check if this is a structured plan request (needs more tokens)
        const isStructuredPlanRequest = messages.some((msg) => {
          if (typeof msg.content !== "string") return false;
          return (msg.content.includes("workout plan") ||
                  msg.content.includes("meal plan") ||
                  msg.content.includes("dietary plan")) &&
            msg.content.includes("JSON");
        });

        const response = await client.chat.completions.create({
          model: "gpt-5-mini",
          messages: openaiMessages,
          temperature: 0.7,
          max_tokens: isStructuredPlanRequest ? 4000 : 1000,
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

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import OpenAI from "openai";

const openaiKey = defineSecret("OPENAI_API_KEY");

interface ContactInput {
  identifier: string;
  givenName: string;
  familyName: string;
  phoneNumbers: string[];
  emailAddresses: string[];
  postalCity: string;
  postalCountry: string;
}

interface LocationGuess {
  identifier: string;
  city: string;
  country: string;
  confidence: "high" | "medium" | "low" | "unknown";
  reason: string;
}

export const guessContactLocations = onCall(
  {
    secrets: [openaiKey],
    region: "europe-west1",
    maxInstances: 10,
    timeoutSeconds: 60,
  },
  async (request) => {
    // Verifiera autentisering
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Requires authentication");
    }

    const contacts: ContactInput[] = request.data.contacts;
    if (!contacts || contacts.length === 0) {
      return { results: [] };
    }

    // Begränsa till max 50 kontakter per anrop
    if (contacts.length > 50) {
      throw new HttpsError(
        "invalid-argument",
        "Maximum 50 contacts per request"
      );
    }

    // Kontakter med direkt adressdata behöver inte AI — returnera direkt
    const needsAI: ContactInput[] = [];
    const directResults: LocationGuess[] = [];

    for (const contact of contacts) {
      if (contact.postalCity && contact.postalCountry) {
        // Adress finns — hög konfidens, ingen AI behövs
        directResults.push({
          identifier: contact.identifier,
          city: contact.postalCity,
          country: contact.postalCountry,
          confidence: "high",
          reason: "Adress från kontaktkort",
        });
      } else {
        needsAI.push(contact);
      }
    }

    // Om alla kontakter hade adresser, returnera direkt
    if (needsAI.length === 0) {
      return { results: directResults };
    }

    // Anropa OpenAI för kontakter utan tydlig adress
    const client = new OpenAI({ apiKey: openaiKey.value() });

    const prompt = buildBatchPrompt(needsAI);

    try {
      const response = await client.chat.completions.create({
        model: "gpt-4o-mini",
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content:
              "You are a location inference assistant. Given contact information (phone numbers, email addresses, names), infer the most likely city and country where the person lives. Return only valid JSON.",
          },
          { role: "user", content: prompt },
        ],
        max_tokens: 2000,
        temperature: 0.1,
      });

      const raw = response.choices[0].message.content ?? '{"results":[]}';
      const parsed = JSON.parse(raw) as { results: LocationGuess[] };

      // Slå ihop direktresultat och AI-gissningar
      return { results: [...directResults, ...parsed.results] };
    } catch (error) {
      console.error("OpenAI API error:", error);
      // Vid AI-fel: returnera direktresultat + "unknown" för resten
      const fallbackResults = needsAI.map((c) => ({
        identifier: c.identifier,
        city: "",
        country: "",
        confidence: "unknown" as const,
        reason: "AI-gissning misslyckades",
      }));
      return { results: [...directResults, ...fallbackResults] };
    }
  }
);

function buildBatchPrompt(contacts: ContactInput[]): string {
  const list = contacts
    .map((c) => {
      const parts: string[] = [];
      if (c.postalCity) parts.push(`city: ${c.postalCity}`);
      if (c.postalCountry) parts.push(`country: ${c.postalCountry}`);
      c.phoneNumbers.forEach((p) => parts.push(`phone: ${p}`));
      c.emailAddresses.forEach((e) => parts.push(`email: ${e}`));
      return `- id: ${c.identifier}, name: ${c.givenName} ${c.familyName}, ${parts.join(", ")}`;
    })
    .join("\n");

  return `For each contact below, infer the most likely city and country where they live.

Rules:
- If a phone number starts with a country code (e.g. +46 = Sweden, +1 = USA, +44 = UK), use the country as a clue (medium confidence).
- If an email domain suggests a country (e.g. .se = Sweden, .de = Germany, .co.uk = UK), use it as a clue (low confidence).
- If both phone country code and email domain agree, increase confidence to medium.
- If no useful clues exist, set city and country to empty strings and confidence to "unknown".
- For the city, guess the capital or largest city of the inferred country if no more specific information exists.

Return JSON: {"results": [{"identifier": "...", "city": "...", "country": "...", "confidence": "high|medium|low|unknown", "reason": "brief explanation"}]}

Contacts:
${list}`;
}

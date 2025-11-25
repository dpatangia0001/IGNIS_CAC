import Foundation
import SwiftUI

class GeminiService: ObservableObject {
    private let apiKey = "AIzaSyC2Noj_mY-ALnyCSrFPSxpstrNCC5lRTL8"
    private let baseURL = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent"

    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {

    }

    func generateFireExpertResponse(for userMessage: String) async -> String {
        isLoading = true
        errorMessage = nil

        let systemPrompt = """
        You are a specialized wildfire safety expert chatbot. Your role is to provide accurate, helpful, and emergency-focused information about wildfires. Always prioritize safety and provide actionable advice.

        Key areas of expertise:
        - Emergency evacuation procedures
        - Fire safety and prevention
        - Air quality and health concerns
        - Emergency contact information
        - Shelter and resource locations
        - Weather and fire conditions
        - Health and medical guidance

        Guidelines:
        - Keep responses concise but comprehensive (2-3 paragraphs max)
        - Use bullet points for easy reading
        - Include emergency numbers when relevant (911, local fire dept)
        - Prioritize immediate safety actions
        - Be encouraging but realistic
        - Use emojis sparingly for emphasis
        - Always ask follow-up questions to help further
        - Focus on practical, actionable advice
        - Include specific steps when possible

        Current user question: \(userMessage)

        Provide a helpful, expert response focused on wildfire safety and emergency procedures.
        """

        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: systemPrompt)
                    ],
                    role: "user"
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                maxOutputTokens: 500
            )
        )

        do {
            let url = URL(string: "\(baseURL)?key=\(apiKey)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData

            print("🌐 Making Gemini API request to: \(url)")
            print("📤 Request body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to encode")")

            let (data, response) = try await URLSession.shared.data(for: request)

            print("📥 Received response with \(data.count) bytes")

            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")

                if httpResponse.statusCode == 200 {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("📄 Raw API Response: \(responseString)")

                    let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                    if let text = geminiResponse.candidates?.first?.content?.parts.first?.text {
                        await MainActor.run {
                            self.isLoading = false
                        }
                        print("✅ Successfully generated response: \(text.prefix(100))...")
                        return text
                    } else {
                        await MainActor.run {
                            self.isLoading = false
                            self.errorMessage = "No response generated"
                        }
                        print("❌ No response text found in API response")
                        return "I'm having trouble generating a response right now. Please try asking about evacuation procedures, fire safety, air quality, emergency contacts, or shelter information."
                    }
                } else {
                    let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ HTTP Error \(httpResponse.statusCode): \(errorString)")

                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "API Error: \(httpResponse.statusCode) - \(errorString)"
                    }
                    return "I'm experiencing technical difficulties (HTTP \(httpResponse.statusCode)). Please try asking about evacuation procedures, fire safety, air quality, emergency contacts, or shelter information."
                }
            }
        } catch {
            print("❌ Network/Decoding Error: \(error)")
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            return "I'm having trouble connecting right now. Please try asking about evacuation procedures, fire safety, air quality, emergency contacts, or shelter information."
        }

        await MainActor.run {
            self.isLoading = false
        }
        return "I'm experiencing technical difficulties. Please try asking about evacuation procedures, fire safety, air quality, emergency contacts, or shelter information."
    }
}

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
    let role: String?
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let topK: Int
    let topP: Double
    let maxOutputTokens: Int
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: PromptFeedback?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
    let index: Int?
    let safetyRatings: [SafetyRating]?
}

struct PromptFeedback: Codable {
    let safetyRatings: [SafetyRating]?
}

struct SafetyRating: Codable {
    let category: String?
    let probability: String?
}

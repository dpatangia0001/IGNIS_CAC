import Foundation
import SwiftUI

class DeepSeekService: ObservableObject {
    private let apiKey = "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"
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"

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

        Response Format Guidelines:
        - Keep responses concise but comprehensive (1-2 paragraphs max)
        - Use simple bullet points with • symbol or numbered lists
        - Write in clear, readable paragraphs
        - Avoid markdown formatting, asterisks, or complex formatting
        - Include emergency numbers when relevant (911, local fire dept)
        - Prioritize immediate safety actions
        - Be realistic and encouraging
        - Always ask follow-up questions to help further
        - Focus on practical, actionable advice
        - Include specific steps when possible
        - Keep responses quick and to the point

        Format Example:
        "Here's what you should do:

        • First step: Do this immediately
        • Second step: Then do this
        • Third step: Finally do this

        Remember to stay calm and follow official instructions. Do you have any other questions about evacuation procedures?"

        Current user question: \(userMessage)

        Provide a helpful, expert response focused on wildfire safety and emergency procedures.
        """

        let requestBody = DeepSeekRequest(
            model: "deepseek-ai/deepseek-r1-0528-qwen3-8b",
            messages: [
                DeepSeekMessage(role: "system", content: systemPrompt),
                DeepSeekMessage(role: "user", content: userMessage)
            ],
            temperature: 0.7,
            max_tokens: 2000
        )

        do {
            let url = URL(string: baseURL)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData

            print("🌐 Making DeepSeek API request to: \(url)")
            print("📤 Request body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to encode")")

            let (data, response) = try await URLSession.shared.data(for: request)

            print("📥 Received response with \(data.count) bytes")

            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")

                if httpResponse.statusCode == 200 {
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("📄 Raw API Response: \(responseString)")

                    let deepSeekResponse = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
                    if let text = deepSeekResponse.choices?.first?.message?.content {
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

struct DeepSeekRequest: Codable {
    let model: String
    let messages: [DeepSeekMessage]
    let temperature: Double
    let max_tokens: Int
}

struct DeepSeekMessage: Codable {
    let role: String
    let content: String
}

struct DeepSeekResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [DeepSeekChoice]?
    let usage: DeepSeekUsage?
}

struct DeepSeekChoice: Codable {
    let index: Int?
    let message: DeepSeekMessage?
    let finish_reason: String?
}

struct DeepSeekUsage: Codable {
    let prompt_tokens: Int?
    let completion_tokens: Int?
    let total_tokens: Int?
}

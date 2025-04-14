import Foundation

class LlamaChat {
    let modelPath: String

    init() {
        // Получаем путь к модели в бандле. Файл должен лежать в ios/llama/models,
        // но он загружается при сборке Codemagic, так что он будет доступен после сборки.
        if let path = Bundle.main.path(forResource: "phi-2.Q4_K_M", ofType: "gguf", inDirectory: "llama/models") {
            self.modelPath = path
        } else {
            self.modelPath = ""
        }
    }

    // Функция для генерации ответа локальной моделью
    func deepThink(prompt: String, history: String) -> String {
        guard !modelPath.isEmpty else { return "Модель не найдена." }
        
        // Преобразуем строки в C-строки
        let promptCStr = (prompt as NSString).utf8String
        let historyCStr = (history as NSString).utf8String
        let modelPathCStr = (modelPath as NSString).utf8String
        
        // Вызов внешней C-функции, реализованной в llama.mm (обёртка вокруг llama.cpp)
        if let resultCString = llama_generate(promptCStr!, historyCStr!, modelPathCStr!) {
            return String(cString: resultCString)
        }
        return "Ошибка генерации ответа."
    }
    
    // Функция для веб-поиска с использованием DuckDuckGo Instant Answer API
    func webSearch(prompt: String, completion: @escaping (String) -> Void) {
        // Кодируем строку запроса для URL
        let encodedPrompt = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.duckduckgo.com/?q=\(encodedPrompt)&format=json&no_redirect=1&skip_disambig=1"
        guard let url = URL(string: urlString) else {
            completion("Ошибка формирования URL для веб-поиска.")
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion("Ошибка: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                completion("Ошибка: нет данных.")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let abstractText = json["AbstractText"] as? String,
                   !abstractText.isEmpty {
                    completion(abstractText)
                } else {
                    completion("Ничего не найдено по запросу: \(prompt)")
                }
            } catch {
                completion("Ошибка обработки результата: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}

// Объявление внешней C-функции, которая реализована в llama.mm (она является мостом к C++ коду из llama.cpp).
@_silgen_name("llama_generate")
func llama_generate(_ prompt: UnsafePointer<CChar>, _ history: UnsafePointer<CChar>, _ modelPath: UnsafePointer<CChar>) -> UnsafePointer<CChar>?

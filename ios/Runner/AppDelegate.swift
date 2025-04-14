// ios/Runner/AppDelegate.swift

import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    let llamaChat = LlamaChat()  // Инициализируем класс-обёртку для работы с моделью и веб-поиском

    override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "mindwave_channel", binaryMessenger: controller.binaryMessenger)

        channel.setMethodCallHandler { (call, result) in
            if call.method == "deepThink" {
                guard let args = call.arguments as? [String: Any],
                      let prompt = args["prompt"] as? String,
                      let history = args["history"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Ожидается prompt и history", details: nil))
                    return
                }
                let response = self.llamaChat.deepThink(prompt: prompt, history: history)
                result(response)
            } else if call.method == "webSearch" {
                guard let args = call.arguments as? [String: Any],
                      let prompt = args["prompt"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Ожидается prompt", details: nil))
                    return
                }
                self.llamaChat.webSearch(prompt: prompt) { response in
                    result(response)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

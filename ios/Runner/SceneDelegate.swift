import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
	override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		super.scene(scene, continue: userActivity)

		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}

		_ = appDelegate.handleIncomingSiriActivity(userActivity)
	}
}

//
// MainViewController.swift
// HomeMap
//

import UIKit
import SceneKit
import ARKit
import RxSwift
import RxCocoa
import AudioToolbox
import VideoToolbox

class MainViewController: UIViewController {

    private let kNeedRenderingPlanes = false

    enum FunctionMode {
        case none
        case placeObject(String)
        case measure
    }

    private var currentMode: FunctionMode = .none
    private var mode = ActionState.length
    
    enum ActionState {
        case length
        case area
        case vase
        case chair
        case candle
        func toAttrStr() -> NSAttributedString {
            var str: String
            switch self {
            case .length:
                str = "Length measurement"
            case .area:
                str = "Area measurement"
            case .vase:
                str = "Vase"
            case .chair:
                str = "Chair"
            case .candle:
                str = "Candle"
            }
            return NSAttributedString(string: str, attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 20),
                                                                NSAttributedStringKey.foregroundColor: UIColor.black])
        }
    }
    
    @IBOutlet weak var resultBarView: UIView!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var infoBarView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!

    private var chartView: ChartView?
    
    private let indicator = UIImageView()
    private let resultLabel = UILabel().then({
        $0.textAlignment = .center
        $0.textColor = UIColor.black
        $0.numberOfLines = 0
        $0.font = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.heavy)
    })
    
    private var line: LineNode?
    private var lineSet: LineSetNode?
    
    private var lines: [LineNode] = []
    private var lineSets: [LineSetNode] = []
    private var planes = [ARPlaneAnchor: Plane]()

    private var objects: [SCNNode] = []
    private var focusSquare: FocusSquare?

    private var mainMenu: MainMenu?
    private var buttonsController: MainButtonsController?
    
    private let disposeBag = DisposeBag()
    
    private var lastState: ARCamera.TrackingState = .notAvailable {
        didSet {
            showTrackingInfo()
        }
    }
    
    private var centerPosition: SCNVector3? {
        return  sceneView.worldPositionFromScreenPosition(self.indicator.center, objectPos: nil).position
    }

    // MARK: The measure calculating

    private var measureUnit = ApplicationSetting.Status.defaultUnit {
        didSet {
            let v = measureValue
            measureValue = v
        }
    }
    
    private var measureValue: MeasurementUnit? {
        didSet {
            if let m = measureValue {
                resultLabel.text = nil
                resultLabel.attributedText = m.attributeString(type: measureUnit)
            } else {
                resultLabel.attributedText = mode.toAttrStr()
            }
        }
    }
    
    private func calculateMeassure() {
        if mode == .length {
            if let currentLineNode = line {
                let length = currentLineNode.length
                measureValue = MeasurementUnit(meterUnitValue: length, isArea: false)
            }
        } else if mode == .area {
            if let lineSetNode = lineSet {
                let area = lineSetNode.area
                measureValue = MeasurementUnit(meterUnitValue: area, isArea: true)
            }
        }
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        restartSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: Layout
    
    private func configureView() {
        setUpChartView()
        setupFocusSquare()
        setUpScene()
        setUpIndicator()
        setUpInfoBar()
        setUpResultsBar()
        setUpButtons()
        layoutMainMenu()
        setUpMainMenuActions()
    }

    private func setUpScene() {
        sceneView.frame = view.bounds
    }
    
    private func setUpIndicator() {
        let width = view.bounds.width
        let height = view.bounds.height
        let x = (width - MainConstants.IndicatorSize)/2
        let y = (height - MainConstants.IndicatorSize)/2
        indicator.image = MainConstants.Image.Indicator.disable
        indicator.frame = CGRect(x: x, y: y, width: MainConstants.IndicatorSize, height: MainConstants.IndicatorSize)
        view.addSubview(indicator)
    }
    
    private func setUpInfoBar() {
        infoBarView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
    }

    // MARK: - Private methods
    
    private func configureObserver() {
        func cleanLine() {
            line?.removeFromParent()
            line = nil
            for node in lines {
                node.removeFromParent()
            }
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main) { _ in
            cleanLine()
        }
    }

    private func showTrackingInfo() {
        switch lastState {
        case .notAvailable:
            guard HUG.isVisible else {
                return
            }
            HUG.show(title: "AR not available")
        case .limited(let reason):
            switch reason {
            case .initializing:
                HUG.show(title: "AR is initializing", message: "Please shake the device to get more feature points", inSource: self)
            case .insufficientFeatures:
                HUG.show(title: "AR excessive motion", message: "Please shake the device to get more feature points", inSource: self)
            case .excessiveMotion:
                HUG.show(title: "AR excessive motion", message: "Device moves too fast", inSource: self)
            case .relocalizing:
                break
            }
        case .normal:
            HUG.dismiss()
        }
    }
    
    private func updateTrackingInfo() {
        
        guard let frame = sceneView.session.currentFrame else {
            return
        }
        let trackingState = frame.camera.trackingState
        
        // Update the UI to provide feedback on the state of the AR experience.
        var message = ""
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal surfaces"
            
        case .notAvailable:
            message = "Tracking unavailable"
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly"
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail"
            
        case .limited(.initializing):
            message = "Initializing AR session"
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
        }
        if let lightEstimate = frame.lightEstimate?.ambientIntensity, lightEstimate < 100  {
            message = "Tracking limited - Too Dark"
        }
        sessionInfoLabel.text = message
    }
}

// MARK: - Results Bar

private extension MainViewController {
    
    private func setUpResultsBar() {
        resultBarView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        resultBarView.clipsToBounds = true
        let tap = UITapGestureRecognizer()
        tap.rx.event.bind(onNext: { recognizer in
            self.measureUnit = self.measureUnit.next()
        }).disposed(by: disposeBag)
        resultLabel.addGestureRecognizer(tap)
        resultLabel.frame = resultBarView.bounds
        resultLabel.isUserInteractionEnabled = true
        resultLabel.attributedText = mode.toAttrStr()
        resultBarView.addSubview(resultLabel)
        
        let copyButton = UIButton(size: CGSize(width: MainConstants.CopyButtonSize, height: MainConstants.CopyButtonSize), image: MainConstants.Image.Result.copy)
        copyButton.frame = CGRect(x: resultBarView.frame.maxX - (10 + MainConstants.CopyButtonSize),
                                  y: 15.0,
                                  width: MainConstants.CopyButtonSize, height: MainConstants.CopyButtonSize)
        _ = copyButton.rx.tap.bind {
            UIPasteboard.general.string = self.resultLabel.text
            HUG.show(title: "Copied to clipboard")
        }
        view.addSubview(copyButton)
    }
}

// MARK: - Chart

private extension MainViewController {

    private func setUpChartView() {
        guard let chartView = Bundle.main.loadNibNamed("ChartView", owner: self, options: nil)?.first as? ChartView else {
            return
        }
        self.chartView = chartView
        let minY = resultBarView.frame.maxY - 20.0
        chartView.configure(self.view, y: minY)
        _ = chartView.currentViewSize.asObservable().subscribe(onNext: {[unowned self] viewSize in
            switch viewSize {
            case .full:
                self.hideButtons(true)
            case .middle:
                self.hideButtons(false)
            case .hide:
                break
            }
        })
    }
    
    private func hideButtons(_ hide: Bool) {
        buttonsController?.isHidden = hide
        indicator.isHidden = hide
        mainMenu?.isHidden = hide
    }
}

// MARK: - Main Menu

private extension MainViewController {
    
    private func layoutMainMenu() {
        let x = view.bounds.width - (MainConstants.SecondButtonsSize + 40)
        let y = view.bounds.height - (MainConstants.SecondButtonsSize + 30)
        let frame = CGRect(x: x, y: y, width: MainConstants.SecondButtonsSize, height: MainConstants.SecondButtonsSize)
        mainMenu = MainMenu(frame: frame)
        view.addSubview(mainMenu!.view)
    }

    private func setUpMainMenuActions() {
        let actionSubscription = mainMenu?.action.asObservable().subscribe(onNext: {[unowned self] actionType in
            switch actionType {
            case .vase:
                self.didTapeOnGalleryItem(.vase)
            case .chair:
                self.didTapeOnGalleryItem(.chair)
            case .candle:
                self.didTapeOnGalleryItem(.candle)
            case .measurement:
                guard let vc = UIStoryboard(name: "SettingViewController", bundle: nil).instantiateInitialViewController() else {
                    return
                }
                self.present(vc, animated: true, completion: nil)
            case .save:
                self.cleanScene()
                self.chartView?.cleanGraph()
                self.restartSceneView()
            case .reset:
                self.changeMeasureMode()
            case .setting:
                self.sceneView.takeScreenshot()
            case .more:
                break
            }
        })
        actionSubscription?.disposed(by: disposeBag)
    }

    private func didTapeOnGalleryItem(_ actionState: ActionState) {
        mode = actionState
        buttonsController?.setUpActionButtons(to: actionState)
        resultLabel.attributedText = mode.toAttrStr()
    }
    
    private func cleanScene() {
        line?.removeFromParent()
        line = nil
        for line in lines {
            line.removeFromParent()
        }
        lineSet?.removeAllLines()
        lineSet = nil
        for lineSet in lineSets {
            lineSet.removeAllLines()
        }
        measureValue = nil
        removeAllObjects()
    }

    private func changeMeasureMode() {
        lineSet = nil
        line = nil
        switch mode {
        case .area:
            buttonsController?.setUpActionButtons(to: .area)
            mode = .length
        case .length:
            buttonsController?.setUpActionButtons(to: .length)
            mode = .area
        case .vase, .chair, .candle:
            buttonsController?.setUpActionButtons(to: .area)
            mode = .length
        }
        resultLabel.attributedText = mode.toAttrStr()
    }
}

// MARK: - Buttons

@objc private extension MainViewController {

    private func setUpButtons() {
        buttonsController = MainButtonsController(view: view)
        let actionSubcription = buttonsController!.action.asObservable().subscribe(onNext: {[unowned self] actionType in
            switch actionType {
            case .finish:
                self.finishButtonPressed()
            case .cancel:
                self.rollBackButtonPressed()
            case .home:
                self.homeButtonPressed()
            }
        })
        actionSubcription.disposed(by: disposeBag)
    }
    
    // Place measuring points, put a gallery item to the scene
    
    func homeButtonPressed() {
        switch mode {
        case .length:
            startLine()
        case .area:
            startLineSet()
        case .vase:
            currentMode = .placeObject("Models.scnassets/vase/vase.scn")
            addAnchorToScene()
        case .chair:
            currentMode = .placeObject("Models.scnassets/chair/chair.scn")
            addAnchorToScene()
        case .candle:
            currentMode = .placeObject("Models.scnassets/candle/candle.scn")
            addAnchorToScene()
        }
    }

    private func addAnchorToScene() {
        if let hit = sceneView.hitTest(indicator.center, types: [.existingPlaneUsingExtent]).first {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        } else if let hit = sceneView.hitTest(indicator.center, types: [.featurePoint]).last {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        }
    }

    // Delete previous operation
    
    func rollBackButtonPressed() {
        switch mode {
        case .length:
            if line != nil {
                line?.removeFromParent()
                line = nil
            } else if let lineLast = lines.popLast() {
                lineLast.removeFromParent()
            } else {
                lineSets.popLast()?.removeAllLines()
            }
        case .area:
            if let ls = lineSet {
                if !ls.removeLastLine() {
                    lineSet = nil
                }
            } else if let lineSetLast = lineSets.popLast() {
                lineSetLast.removeAllLines()
            } else {
                lines.popLast()?.removeFromParent()
            }
        case .vase, .chair, .candle:
            if let object = self.objects.last {
                object.removeFromParentNode()
            }
        }
        buttonsController?.homeCancelState = MainButtonsController.HomeCancelState.Delete
        measureValue = nil
    }
    
    // Complete area measurement
    
    func finishButtonPressed() {
        guard mode == .area else {
            return
        }
        closeArea()
        buttonsController?.finishButton(show: false)
    }
    
    private func startLine() {
        if let lineNode = line {
            lines.append(lineNode)
            line = nil
        } else  if let centerPosition = centerPosition {
            line = LineNode(startPos: centerPosition, sceneV: sceneView)
        }
    }
    
    private func startLineSet() {
        if let currLineSet = lineSet {
            currLineSet.startLine()
        } else if let centerPosition = centerPosition {
            lineSet = LineSetNode(sceneView: sceneView)
            lineSet?.startLine(at: centerPosition)
        }
    }
    
    private func closeArea() {
        guard let currLineSet = lineSet, currLineSet.lines.count >= 2 else {
            lineSet = nil
            return
        }
        currLineSet.terminateSet()
        lineSet = nil
        lineSets.append(currLineSet)
        chartView?.present(lineSet: currLineSet)
    }
}

// MARK: - Restart Scene

fileprivate extension MainViewController {
    
    private func restartSceneView() {
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self   // ARSessionDelegate
        sceneView.delegate = self           // ARSCNViewDelegate
        
        #if DEBUG
            sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
            // Show debug UI to view performance metrics (e.g. frames per second).
            sceneView.showsStatistics = true
        #endif
        
        measureUnit = ApplicationSetting.Status.defaultUnit
        resultLabel.attributedText = mode.toAttrStr()
        updateFocusSquare()
    }
}

// MARK： - AR
// MARK: - Plane

fileprivate extension MainViewController {

    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        let plane = Plane(anchor, false)
        planes[anchor] = plane
        node.addChildNode(plane)
        indicator.image = MainConstants.Image.Indicator.enable
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
}

// MARK: - FocusSquare

fileprivate extension MainViewController {
    
    func setupFocusSquare() {
        focusSquare?.isHidden = true
        focusSquare?.removeFromParentNode()
        focusSquare = FocusSquare()
        sceneView.scene.rootNode.addChildNode(focusSquare!)
    }
    
    func updateFocusSquare() {
        focusSquare?.unhide()
        let (worldPos, planeAnchor, _) = sceneView.worldPositionFromScreenPosition(sceneView.bounds.mid, objectPos: focusSquare?.position)
        if let worldPos = worldPos {
            focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
        }
    }
}

// MARK: - ARSCNViewDelegate

extension MainViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        if let planeAnchor = anchor as? ARPlaneAnchor {
            DispatchQueue.main.async {
                self.updateTrackingInfo()
                self.addPlane(node: node, anchor: planeAnchor)
                if self.kNeedRenderingPlanes {
                    self.render(node: node, for: planeAnchor)
                }
            }
        } else {
            switch self.currentMode {
            case .placeObject(let name):
                let objectNode = nodeWithModelName(name)
                self.objects.append(objectNode)
                objectNode.position = SCNVector3Zero
                node.addChildNode(objectNode)
            case .none, .measure:
                break
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        if let planeAnchor = anchor as?  ARPlaneAnchor {
            DispatchQueue.main.async {
                self.updatePlane(anchor: planeAnchor)
            }
            if let planeNode = node.childNodes.first, let plane = planeNode.geometry as? SCNPlane {
                // Plane estimation may shift the center of a plane relative to its anchor's transform.
                planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
                
                // Plane estimation may also extend planes, or remove one plane to merge its extent into another.
                plane.width = CGFloat(planeAnchor.extent.x)
                plane.height = CGFloat(planeAnchor.extent.z)
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateTrackingInfo()
            self.updateFocusSquare()
            self.updateLine()
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            self.updateTrackingInfo()
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.removePlane(anchor: planeAnchor)
            }
        }
    }

    private func updateLine() -> Void {
        guard let currCenterPosition = centerPosition  else {
            return
        }
        let camera = self.sceneView.session.currentFrame?.camera
        let cameraPos = SCNVector3.positionFromTransform(camera!.transform)
        if cameraPos.distanceFromPos(pos: currCenterPosition) < 0.05 {
            if line == nil {
                buttonsController?.homeCancelState = MainButtonsController.HomeCancelState.HomeDisabled
                indicator.image = MainConstants.Image.Indicator.disable
            }
            return;
        }
        buttonsController?.homeCancelState = MainButtonsController.HomeCancelState.HomeEnabled
        indicator.image = MainConstants.Image.Indicator.enable
        if mode == .length {
            guard let currentLineNode = line else {
                buttonsController?.homeCancelState = MainButtonsController.HomeCancelState.Delete
                return
            }
            currentLineNode.terminateLine(at: currCenterPosition, camera: camera)
            buttonsController?.homeCancelState = MainButtonsController.HomeCancelState.Cancel
            calculateMeassure()
        } else if mode == .area {
            guard let lineSetNode = lineSet else {
                buttonsController?.finishButton(show: false)
                buttonsController?.homeCancelState = MainButtonsController.HomeCancelState.Delete
                return
            }
            lineSetNode.terminateLine(at: currCenterPosition, camera: camera)
            buttonsController?.finishButton(show: lineSetNode.area >= 0)
            buttonsController?.homeCancelState = MainButtonsController.HomeCancelState.Cancel
            calculateMeassure()
        }
    }
    
    // Render content for anchors found by plane detection.
    private func render(node: SCNNode, for planeAnchor: ARPlaneAnchor) {
        
        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // `SCNPlane` is vertically oriented in its local coordinate space, so
        // rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
        planeNode.eulerAngles.x = -.pi / 2
        
        // Make the plane visualization semitransparent to clearly show real-world placement.
        planeNode.opacity = 0.25
        
        // Add the plane visualization to the ARKit-managed node so that it tracks
        // changes in the plane anchor as plane estimation continues.
        node.addChildNode(planeNode)
    }
    
    private func removeAllObjects() {
        for object in objects {
            object.removeFromParentNode()
        }
        
        objects = []
    }
}

// MARK: - ARSessionDelegate

extension MainViewController: ARSessionDelegate {
    
    /**
     This is called when a new frame has been updated.
     
     @param session The session being run.
     @param frame The frame that has been updated.
     */
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    }
    /**
     This is called when anchors are updated.
     
     @param session The session being run.
     @param anchors An array of updated anchors.
     */
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    }
    
    /**
     This is called when new anchors are added to the session.
     
     @param session The session being run.
     @param anchors An array of added anchors.
     */
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        updateTrackingInfo()
    }
    
    /**
     This is called when anchors are removed from the session.
     
     @param session The session being run.
     @param anchors An array of removed anchors.
     */
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        updateTrackingInfo()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            HUG.show(title: (error as NSError).localizedDescription)
        }
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let state = camera.trackingState
        DispatchQueue.main.async {
            self.updateTrackingInfo()
            self.lastState = state
        }
    }
}

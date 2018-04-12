import UIKit
import PlaygroundSupport
import GameplayKit
import AVFoundation
//:## Trajector
//"Trajector" is a spaceship simulation game. It uses UIDynamics to simulate gravity and collision.

public class SpaceshipGame: UIViewController, UICollisionBehaviorDelegate {
    let screen = Screen() // I need this information before the liveview is initialized, so I stored it.
    var planets: [Planet] = [Planet]() // The planet array. Each member is a planet
    var goal: UIView! // The goal line to reach.
    var spaceship = Ellipse() // The spaceship
    
    var animator: UIDynamicAnimator! // The overall animator
    var collision: UICollisionBehavior! // Handles collision between planets and spaceship; spaceship and goaline
    var continuousPush: UIPushBehavior! // Pushes the spaceship
    var instantPush: UIPushBehavior! // Pushes the spaceship
    
    var tapRecognizer: UITapGestureRecognizer! // Gives the spaceship an instant push
    var longPressRecognizer: UILongPressGestureRecognizer! // Gives the spaceship a continuous push
    
    var giveUpButton: UIButton!
    var fuelLabel: UILabel = UILabel()
    var fuelIndicator: UIView? // Indicates how much fuel is left
    var levelNumberLabel: UILabel! // Indicates the level
    var tutorialLabel: UILabel! // Label on top
    
    var player = AVAudioPlayer() // Plays sound effect
    var backgroundMusicPlayer = AVAudioPlayer() // Plays background music
    
    let shipRadius = 20.0 // The radius of space ship
    let goalHeight = 5.0
    var goalWidth = 130.0
    var currentLevel = 1 //Defines the level to begin. Feel free to change this number to change your start level
    var isGravityInitialized = false
    
    public required init?(coder: NSCoder) {
        fatalError()
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func loadView() {
        let view = UIView()
        let backgroundColor: CGFloat = 250.0/255.0
        view.backgroundColor = UIColor(red: backgroundColor, green: backgroundColor, blue: backgroundColor, alpha: 1)
        
        self.view = view
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        initializeAllViewsAndAnimations()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        print(view.frame.size)
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(continuePushingIt(_:)))
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(giveItAPush(_:)))
        view.addGestureRecognizer(tapRecognizer)
        view.addGestureRecognizer(longPressRecognizer)
        if currentLevel == 1 {
            longPressRecognizer.isEnabled = false
        }
        
        playBackgroundMusic()
        
    }
    
    func initializeAllViewsAndAnimations() {
        //Initialize animator
        animator = UIDynamicAnimator(referenceView: view)
        
        //Initialize spaceship
        spaceship = Ellipse(frame: CGRect(x: screen.midX - shipRadius, y: screen.height - shipRadius, width: 2*shipRadius, height: 2*shipRadius))
        spaceship.layer.cornerRadius = CGFloat(shipRadius)
        spaceship.layer.masksToBounds = true
        spaceship.backgroundColor = UIColor.red
        spaceship.layer.contents = UIImage(named: "Spaceship.jpg")?.cgImage
        view.addSubview(spaceship)
        
        //Initialize tutorial label
        tutorialLabel = UILabel()
        tutorialLabel.textColor = UIColor.darkGray
        tutorialLabel.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        tutorialLabel.textAlignment = .center
        tutorialLabel.numberOfLines = 0
        tutorialLabel.lineBreakMode = .byWordWrapping
        tutorialLabel.frame = CGRect(x: 30, y: 70, width: screen.width - 60, height: 200)
        tutorialLabel.text = "Loading..."
        view.addSubview(tutorialLabel)
        
        switch currentLevel {
        case 1:
            goalWidth = 130.0
            
            planets = [Planet(centerX: screen.midX, centerY: screen.midY, radius: 70.0)]
        case 2:
            goalWidth = 70.0
            
            planets = [Planet(centerX: screen.midX, centerY: screen.midY, radius: 70.0)]
        case 3:
            goalWidth = 70.0
            
            planets = [Planet(centerX: 40, centerY: 500, radius: 30), Planet(centerX: 335, centerY: 250, radius: 30)]
        default:
            goalWidth = 70.0
            generateRandomPlanets()
        }
        addPlanetsToView()
        
        if currentLevel != 1 {
            // Initialize fuel label
            fuelLabel.text = "Fuel"
            fuelLabel.textColor = UIColor.darkGray
            fuelLabel.frame = CGRect(x: 300, y: 320, width: 70, height: 30)
            view.addSubview(fuelLabel)
            
            // Initialize fuel indicator
            fuelIndicator = UIView()
            fuelIndicator?.frame = CGRect.init(x: 310, y: 350, width: 15, height: 200)
            fuelIndicator?.backgroundColor = UIColor.gray
            fuelIndicator?.layer.cornerRadius = 5
            view.addSubview(fuelIndicator!)
        }
        
        // Initialize level label
        levelNumberLabel = UILabel()
        levelNumberLabel.text = "Level " + String(currentLevel)
        levelNumberLabel.textColor = UIColor.darkGray
        levelNumberLabel.frame = CGRect(x: 30, y: 30, width: 70, height: 30)
        view.addSubview(levelNumberLabel)
        
        // Display the tutorial text
        var tutorialText: String {
            switch currentLevel {
            case 1:
                return "Tap anywhere to launch your spaceship in that direction. Shoot for the goal line on top ↑."
            case 2:
                return "After launch, tap or long press to use the engine on the spaceship. But be careful: Fuel supply is limited!"
            case 3:
                return "Now let's begin our journey."
            default:
                return ""
            }
        }
        tutorialLabel.text = tutorialText
        
        // Initialize goal indicator
        goal = UIView(frame: CGRect(x: (screen.width - goalWidth)/2, y: goalHeight, width: goalWidth, height: goalHeight))
        goal.layer.cornerRadius = CGFloat(goalHeight/2)
        goal.layer.masksToBounds = true
        goal.backgroundColor = UIColor.darkGray
        view.addSubview(goal)
        
        // Initialize the give up button
        giveUpButton = UIButton()
        giveUpButton.addTarget(self, action: #selector(giveUp), for: .touchUpInside)
        giveUpButton.setTitle("Give up", for: .normal)
        giveUpButton.setTitleColor(UIColor.darkGray, for: .normal)
        giveUpButton.frame = CGRect(x: 280, y: 30, width: 70, height: 30)
        
        // Add elasticity to items
        let itemBehaviour = UIDynamicItemBehavior(items: planets as [UIView] + [spaceship])
        itemBehaviour.elasticity = 0.8
        animator.addBehavior(itemBehaviour)
        
        // Add collision
        collision = UICollisionBehavior(items: planets as [UIView] + [spaceship, goal])
        collision.translatesReferenceBoundsIntoBoundary = true
        collision.collisionDelegate = self
        animator.addBehavior(collision)
        
        // Add push
        continuousPush = UIPushBehavior.init(items: [spaceship], mode: .continuous)
        continuousPush.magnitude = 0.5
        continuousPush.active = false
        animator.addBehavior(continuousPush)
        
        instantPush = UIPushBehavior.init(items: [spaceship], mode: .instantaneous)
        instantPush.magnitude = 0.3
        instantPush.active = false
        animator.addBehavior(instantPush)
        
        // Gravity is not initialized yet at the start
        isGravityInitialized = false
    }
    
    func addPlanetsToView() {
        for planet in planets {
            view.addSubview(planet)
            animator.addBehavior(planet.attachment)
            planet.gravity!.addItem(spaceship)
        }
    }
    
    func playBackgroundMusic() {
        guard let url = Bundle.main.url(forResource: "BGM", withExtension: "mp3") else {
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer.numberOfLoops = -1
            backgroundMusicPlayer.prepareToPlay()
            backgroundMusicPlayer.play()
        } catch let error as NSError {
            print(error.description)
        }
    }
    
    func generateRandomPlanets() {
        let random = GKRandomSource()
        let numberOfPlanets = GKGaussianDistribution(randomSource: random, lowestValue: 1, highestValue: 6).nextInt()
        for _ in 1...numberOfPlanets {
            planets += [generateARandomPlanet()]
        }
    }
    
    func generateARandomPlanet() -> Planet {
        let random = GKRandomSource()
        let radius = GKRandomDistribution(randomSource: random, lowestValue: 10, highestValue: 60).nextInt()
        // At least half of the planet is in display to prevent "mysterious gravity" (when you "feel" a gravitational force but see no planet)
        let x = GKRandomDistribution(randomSource: random, lowestValue: 0, highestValue: Int(screen.width) - radius).nextInt()
        
        // Between the spaceship and the goal line
        let y = GKRandomDistribution(randomSource: random, lowestValue: Int(2*goalHeight) + radius, highestValue: Int(screen.height) - radius - Int(shipRadius)).nextInt()
        var planetToReturn = Planet(centerX: Double(x), centerY: Double(y), radius: Double(radius), density: 0.8)
        for planet in planets {
            let deltaX = fabs(planet.frame.midX - planetToReturn.frame.midX)
            let deltaY = fabs(planet.frame.midY - planetToReturn.frame.midY)
            let distance = sqrt(deltaX*deltaX + deltaY*deltaY)
            let minimalDistance = planet.frame.height + planetToReturn.frame.height
            if distance < minimalDistance {
                // Simple recursion: If this planet collides with other planets, generate a new one.
                planetToReturn = generateARandomPlanet()
                return planetToReturn
            }
        }
        return planetToReturn
    }
    
    func enableAllGesture() {
        tapRecognizer.isEnabled = true
        if currentLevel != 1 {
            longPressRecognizer.isEnabled = true
        }
    }
    
    func removeAllViews() {
        for planet in planets {
            planet.removeFromSuperview()
        }
        planets = [Planet]()
        spaceship.removeFromSuperview()
        goal.removeFromSuperview()
        giveUpButton.removeFromSuperview()
        levelNumberLabel.removeFromSuperview()
        tutorialLabel.removeFromSuperview()
        if currentLevel != 1 {
            fuelLabel.removeFromSuperview()
            fuelIndicator?.removeFromSuperview()
        }
    }
    
    // When you click "Give uo" button
    @objc func giveUp() {
        animator.removeAllBehaviors()
        let goalReachedAlert = UIAlertController(title: "So close!", message: "Wanna try again?", preferredStyle: .alert)
        goalReachedAlert.addAction(UIAlertAction(title: "Try again", style: .default, handler: { _ in
            self.removeAllViews()
            self.initializeAllViewsAndAnimations()
            self.enableAllGesture()
        }))
        self.present(goalReachedAlert, animated: true)
    }
    
    // Long press to push continuously
    @objc func continuePushingIt(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .ended {
            let gesturePoint = gestureRecognizer.location(in: view)
            continuousPush.angle = pushAngle(at: gesturePoint)
            continuousPush.active = true
            
            guard fuelIndicator != nil else {
                return
            }
            if fuelIndicator!.frame.height >= 1 {
                fuelIndicator!.frame.size.height = fuelIndicator!.frame.height - 1
            } else {
                continuousPush.active = false
                longPressRecognizer.isEnabled = false
            }
        } else {
            continuousPush.active = false
        }
    }
    
    // A instant push
    @objc func giveItAPush(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if !isGravityInitialized {
            beginsTheGame()
        }
        
        if fuelIndicator != nil {
            guard fuelIndicator!.frame.height >= 50 else {
                tapRecognizer.isEnabled = false
                return
            }
            
            let gesturePoint = gestureRecognizer.location(in: view)
            instantPush.angle = pushAngle(at: gesturePoint)
            instantPush.active = true
            fuelIndicator!.frame.size.height -= 50
        } else {
            let gesturePoint = gestureRecognizer.location(in: view)
            instantPush.angle = pushAngle(at: gesturePoint)
            instantPush.active = true
            tapRecognizer.isEnabled = false
            longPressRecognizer.isEnabled = false
        }
        
        playSoundEffect(name: "Spaceship")
    }
    
    // Initialize gravity; remove tutorial label; add "Give up" button after 4 seconds
    func beginsTheGame() {
        tutorialLabel.removeFromSuperview()
        
        for planet in planets {
            animator.addBehavior(planet.gravity)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
            self.view.addSubview(self.giveUpButton)
        })
    }
    
    // Calculate which angle should the spaceship go
    func pushAngle(at gesturePoint: CGPoint) -> CGFloat {
        let shipPoint = spaceship.frame
        let deltaX = gesturePoint.x - shipPoint.midX
        let deltaY = gesturePoint.y - shipPoint.midY
        var angle = atan2(deltaY, deltaX)
        angle = angle < 0 ? (angle + 2*CGFloat.pi) : angle
        return angle
    }
    
    public func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item1: UIDynamicItem, with item2: UIDynamicItem, at p: CGPoint) {
        playSoundEffect(name: "Collision")
        
        if (item1.isEqual(goal) || item2.isEqual(goal)) && (!item1.isKind(of: Planet.self) && !item2.isKind(of: Planet.self)) {
            print("Goal reached!")
            self.nextLevel()
        }
        //        let explosion = SKEmitterNode()
        //        explosion.position = p
    }
    
    func playSoundEffect(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    // Continues to the next level
    func nextLevel() {
        animator.removeAllBehaviors()
        tutorialLabel.text = "Great! You've reached your goal!"
        view.addSubview(tutorialLabel)
        playSoundEffect(name: "Success")
        UIView.animate(withDuration: 2) {
            for planet in self.planets {
                planet.frame.origin.y += CGFloat(self.screen.height)
            }
            
            self.spaceship.frame.origin = CGPoint(x: self.screen.midX - self.shipRadius, y: self.screen.height - 2*self.shipRadius)
        }
        
        //
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.removeAllViews()
            self.currentLevel += 1
            self.initializeAllViewsAndAnimations()
            self.enableAllGesture()
        }
    }
}


// Present the view controller in the Live View window
PlaygroundPage.current.liveView = SpaceshipGame()

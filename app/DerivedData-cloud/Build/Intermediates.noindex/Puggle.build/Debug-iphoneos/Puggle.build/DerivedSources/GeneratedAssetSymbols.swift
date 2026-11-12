import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "Sand" asset catalog color resource.
    static let sand = DeveloperToolsSupport.ColorResource(name: "Sand", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "PuggleFace" asset catalog image resource.
    static let puggleFace = DeveloperToolsSupport.ImageResource(name: "PuggleFace", bundle: resourceBundle)

    /// The "PuggleMark" asset catalog image resource.
    static let puggleMark = DeveloperToolsSupport.ImageResource(name: "PuggleMark", bundle: resourceBundle)

    /// The "PuggleStill" asset catalog image resource.
    static let puggleStill = DeveloperToolsSupport.ImageResource(name: "PuggleStill", bundle: resourceBundle)

    /// The "icon-bath" asset catalog image resource.
    static let iconBath = DeveloperToolsSupport.ImageResource(name: "icon-bath", bundle: resourceBundle)

    /// The "icon-bath-plain" asset catalog image resource.
    static let iconBathPlain = DeveloperToolsSupport.ImageResource(name: "icon-bath-plain", bundle: resourceBundle)

    /// The "icon-bottle" asset catalog image resource.
    static let iconBottle = DeveloperToolsSupport.ImageResource(name: "icon-bottle", bundle: resourceBundle)

    /// The "icon-bottle-plain" asset catalog image resource.
    static let iconBottlePlain = DeveloperToolsSupport.ImageResource(name: "icon-bottle-plain", bundle: resourceBundle)

    /// The "icon-breastfeed" asset catalog image resource.
    static let iconBreastfeed = DeveloperToolsSupport.ImageResource(name: "icon-breastfeed", bundle: resourceBundle)

    /// The "icon-breastfeed-plain" asset catalog image resource.
    static let iconBreastfeedPlain = DeveloperToolsSupport.ImageResource(name: "icon-breastfeed-plain", bundle: resourceBundle)

    /// The "icon-growth" asset catalog image resource.
    static let iconGrowth = DeveloperToolsSupport.ImageResource(name: "icon-growth", bundle: resourceBundle)

    /// The "icon-growth-plain" asset catalog image resource.
    static let iconGrowthPlain = DeveloperToolsSupport.ImageResource(name: "icon-growth-plain", bundle: resourceBundle)

    /// The "icon-medicine" asset catalog image resource.
    static let iconMedicine = DeveloperToolsSupport.ImageResource(name: "icon-medicine", bundle: resourceBundle)

    /// The "icon-medicine-plain" asset catalog image resource.
    static let iconMedicinePlain = DeveloperToolsSupport.ImageResource(name: "icon-medicine-plain", bundle: resourceBundle)

    /// The "icon-milestone" asset catalog image resource.
    static let iconMilestone = DeveloperToolsSupport.ImageResource(name: "icon-milestone", bundle: resourceBundle)

    /// The "icon-milestone-plain" asset catalog image resource.
    static let iconMilestonePlain = DeveloperToolsSupport.ImageResource(name: "icon-milestone-plain", bundle: resourceBundle)

    /// The "icon-nappy" asset catalog image resource.
    static let iconNappy = DeveloperToolsSupport.ImageResource(name: "icon-nappy", bundle: resourceBundle)

    /// The "icon-nappy-plain" asset catalog image resource.
    static let iconNappyPlain = DeveloperToolsSupport.ImageResource(name: "icon-nappy-plain", bundle: resourceBundle)

    /// The "icon-note" asset catalog image resource.
    static let iconNote = DeveloperToolsSupport.ImageResource(name: "icon-note", bundle: resourceBundle)

    /// The "icon-note-plain" asset catalog image resource.
    static let iconNotePlain = DeveloperToolsSupport.ImageResource(name: "icon-note-plain", bundle: resourceBundle)

    /// The "icon-photo" asset catalog image resource.
    static let iconPhoto = DeveloperToolsSupport.ImageResource(name: "icon-photo", bundle: resourceBundle)

    /// The "icon-photo-plain" asset catalog image resource.
    static let iconPhotoPlain = DeveloperToolsSupport.ImageResource(name: "icon-photo-plain", bundle: resourceBundle)

    /// The "icon-play" asset catalog image resource.
    static let iconPlay = DeveloperToolsSupport.ImageResource(name: "icon-play", bundle: resourceBundle)

    /// The "icon-play-plain" asset catalog image resource.
    static let iconPlayPlain = DeveloperToolsSupport.ImageResource(name: "icon-play-plain", bundle: resourceBundle)

    /// The "icon-potty" asset catalog image resource.
    static let iconPotty = DeveloperToolsSupport.ImageResource(name: "icon-potty", bundle: resourceBundle)

    /// The "icon-potty-plain" asset catalog image resource.
    static let iconPottyPlain = DeveloperToolsSupport.ImageResource(name: "icon-potty-plain", bundle: resourceBundle)

    /// The "icon-pump" asset catalog image resource.
    static let iconPump = DeveloperToolsSupport.ImageResource(name: "icon-pump", bundle: resourceBundle)

    /// The "icon-pump-plain" asset catalog image resource.
    static let iconPumpPlain = DeveloperToolsSupport.ImageResource(name: "icon-pump-plain", bundle: resourceBundle)

    /// The "icon-sleep" asset catalog image resource.
    static let iconSleep = DeveloperToolsSupport.ImageResource(name: "icon-sleep", bundle: resourceBundle)

    /// The "icon-sleep-plain" asset catalog image resource.
    static let iconSleepPlain = DeveloperToolsSupport.ImageResource(name: "icon-sleep-plain", bundle: resourceBundle)

    /// The "icon-solids" asset catalog image resource.
    static let iconSolids = DeveloperToolsSupport.ImageResource(name: "icon-solids", bundle: resourceBundle)

    /// The "icon-solids-plain" asset catalog image resource.
    static let iconSolidsPlain = DeveloperToolsSupport.ImageResource(name: "icon-solids-plain", bundle: resourceBundle)

    /// The "icon-teeth" asset catalog image resource.
    static let iconTeeth = DeveloperToolsSupport.ImageResource(name: "icon-teeth", bundle: resourceBundle)

    /// The "icon-teeth-plain" asset catalog image resource.
    static let iconTeethPlain = DeveloperToolsSupport.ImageResource(name: "icon-teeth-plain", bundle: resourceBundle)

    /// The "icon-temperature" asset catalog image resource.
    static let iconTemperature = DeveloperToolsSupport.ImageResource(name: "icon-temperature", bundle: resourceBundle)

    /// The "icon-temperature-plain" asset catalog image resource.
    static let iconTemperaturePlain = DeveloperToolsSupport.ImageResource(name: "icon-temperature-plain", bundle: resourceBundle)

    /// The "icon-tummy-time" asset catalog image resource.
    static let iconTummyTime = DeveloperToolsSupport.ImageResource(name: "icon-tummy-time", bundle: resourceBundle)

    /// The "icon-tummy-time-plain" asset catalog image resource.
    static let iconTummyTimePlain = DeveloperToolsSupport.ImageResource(name: "icon-tummy-time-plain", bundle: resourceBundle)

    /// The "icon-vaccine" asset catalog image resource.
    static let iconVaccine = DeveloperToolsSupport.ImageResource(name: "icon-vaccine", bundle: resourceBundle)

    /// The "icon-vaccine-plain" asset catalog image resource.
    static let iconVaccinePlain = DeveloperToolsSupport.ImageResource(name: "icon-vaccine-plain", bundle: resourceBundle)

    /// The "icon-walk" asset catalog image resource.
    static let iconWalk = DeveloperToolsSupport.ImageResource(name: "icon-walk", bundle: resourceBundle)

    /// The "icon-walk-plain" asset catalog image resource.
    static let iconWalkPlain = DeveloperToolsSupport.ImageResource(name: "icon-walk-plain", bundle: resourceBundle)

    /// The "icon-weight" asset catalog image resource.
    static let iconWeight = DeveloperToolsSupport.ImageResource(name: "icon-weight", bundle: resourceBundle)

    /// The "icon-weight-plain" asset catalog image resource.
    static let iconWeightPlain = DeveloperToolsSupport.ImageResource(name: "icon-weight-plain", bundle: resourceBundle)

    /// The "shape-blossom" asset catalog image resource.
    static let shapeBlossom = DeveloperToolsSupport.ImageResource(name: "shape-blossom", bundle: resourceBundle)

    /// The "shape-half-pill" asset catalog image resource.
    static let shapeHalfPill = DeveloperToolsSupport.ImageResource(name: "shape-half-pill", bundle: resourceBundle)

    /// The "shape-pebble" asset catalog image resource.
    static let shapePebble = DeveloperToolsSupport.ImageResource(name: "shape-pebble", bundle: resourceBundle)

    /// The "shape-pill" asset catalog image resource.
    static let shapePill = DeveloperToolsSupport.ImageResource(name: "shape-pill", bundle: resourceBundle)

    /// The "shape-quatrefoil" asset catalog image resource.
    static let shapeQuatrefoil = DeveloperToolsSupport.ImageResource(name: "shape-quatrefoil", bundle: resourceBundle)

    /// The "shape-scallop" asset catalog image resource.
    static let shapeScallop = DeveloperToolsSupport.ImageResource(name: "shape-scallop", bundle: resourceBundle)

    /// The "shape-soft-hexagon" asset catalog image resource.
    static let shapeSoftHexagon = DeveloperToolsSupport.ImageResource(name: "shape-soft-hexagon", bundle: resourceBundle)

    /// The "shape-soft-square" asset catalog image resource.
    static let shapeSoftSquare = DeveloperToolsSupport.ImageResource(name: "shape-soft-square", bundle: resourceBundle)

    /// The "stamp-balloon" asset catalog image resource.
    static let stampBalloon = DeveloperToolsSupport.ImageResource(name: "stamp-balloon", bundle: resourceBundle)

    /// The "stamp-butterfly" asset catalog image resource.
    static let stampButterfly = DeveloperToolsSupport.ImageResource(name: "stamp-butterfly", bundle: resourceBundle)

    /// The "stamp-cricket" asset catalog image resource.
    static let stampCricket = DeveloperToolsSupport.ImageResource(name: "stamp-cricket", bundle: resourceBundle)

    /// The "stamp-duck" asset catalog image resource.
    static let stampDuck = DeveloperToolsSupport.ImageResource(name: "stamp-duck", bundle: resourceBundle)

    /// The "stamp-duck-cut" asset catalog image resource.
    static let stampDuckCut = DeveloperToolsSupport.ImageResource(name: "stamp-duck-cut", bundle: resourceBundle)

    /// The "stamp-esky" asset catalog image resource.
    static let stampEsky = DeveloperToolsSupport.ImageResource(name: "stamp-esky", bundle: resourceBundle)

    /// The "stamp-fairy-bread" asset catalog image resource.
    static let stampFairyBread = DeveloperToolsSupport.ImageResource(name: "stamp-fairy-bread", bundle: resourceBundle)

    /// The "stamp-fish" asset catalog image resource.
    static let stampFish = DeveloperToolsSupport.ImageResource(name: "stamp-fish", bundle: resourceBundle)

    /// The "stamp-heart" asset catalog image resource.
    static let stampHeart = DeveloperToolsSupport.ImageResource(name: "stamp-heart", bundle: resourceBundle)

    /// The "stamp-hills-hoist" asset catalog image resource.
    static let stampHillsHoist = DeveloperToolsSupport.ImageResource(name: "stamp-hills-hoist", bundle: resourceBundle)

    /// The "stamp-kangaroo" asset catalog image resource.
    static let stampKangaroo = DeveloperToolsSupport.ImageResource(name: "stamp-kangaroo", bundle: resourceBundle)

    /// The "stamp-lamington" asset catalog image resource.
    static let stampLamington = DeveloperToolsSupport.ImageResource(name: "stamp-lamington", bundle: resourceBundle)

    /// The "stamp-moon" asset catalog image resource.
    static let stampMoon = DeveloperToolsSupport.ImageResource(name: "stamp-moon", bundle: resourceBundle)

    /// The "stamp-pavlova" asset catalog image resource.
    static let stampPavlova = DeveloperToolsSupport.ImageResource(name: "stamp-pavlova", bundle: resourceBundle)

    /// The "stamp-star" asset catalog image resource.
    static let stampStar = DeveloperToolsSupport.ImageResource(name: "stamp-star", bundle: resourceBundle)

    /// The "stamp-sun" asset catalog image resource.
    static let stampSun = DeveloperToolsSupport.ImageResource(name: "stamp-sun", bundle: resourceBundle)

    /// The "stamp-surfboard" asset catalog image resource.
    static let stampSurfboard = DeveloperToolsSupport.ImageResource(name: "stamp-surfboard", bundle: resourceBundle)

    /// The "stamp-surfboard-cut" asset catalog image resource.
    static let stampSurfboardCut = DeveloperToolsSupport.ImageResource(name: "stamp-surfboard-cut", bundle: resourceBundle)

    /// The "stamp-thong" asset catalog image resource.
    static let stampThong = DeveloperToolsSupport.ImageResource(name: "stamp-thong", bundle: resourceBundle)

    /// The "stamp-thong-cut" asset catalog image resource.
    static let stampThongCut = DeveloperToolsSupport.ImageResource(name: "stamp-thong-cut", bundle: resourceBundle)

    /// The "stamp-train" asset catalog image resource.
    static let stampTrain = DeveloperToolsSupport.ImageResource(name: "stamp-train", bundle: resourceBundle)

}


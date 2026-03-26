import UIKit

/// Provides sample gym image data for demo/simulator testing.
/// Generates simple labeled images that the backend vision model can interpret,
/// or loads bundled sample images if available.
enum DemoDataProvider {

    /// Returns a set of JPEG-encoded frames representing a hotel gym.
    /// These are synthetic images with equipment labels that the AI can parse.
    static func sampleFrames() -> [Data] {
        // Try to load bundled images first
        let bundledFrames = loadBundledImages()
        if !bundledFrames.isEmpty {
            return bundledFrames
        }

        // Fall back to generating labeled images for the vision model
        return generateLabeledFrames()
    }

    // MARK: - Bundled images

    private static func loadBundledImages() -> [Data] {
        let imageNames = ["demo_gym_1", "demo_gym_2", "demo_gym_3"]
        var frames: [Data] = []
        for name in imageNames {
            if let image = UIImage(named: name),
               let data = image.jpegData(compressionQuality: 0.8) {
                frames.append(data)
            }
        }
        return frames
    }

    // MARK: - Generated frames

    private static func generateLabeledFrames() -> [Data] {
        let frameConfigs: [(String, [String])] = [
            ("Hotel Gym - Section 1", [
                "Dumbbell rack (5-50 lbs)",
                "Adjustable bench",
                "Cable machine",
                "Flat bench"
            ]),
            ("Hotel Gym - Section 2", [
                "Treadmill",
                "Stationary bike",
                "Elliptical",
                "Rowing machine"
            ]),
            ("Hotel Gym - Section 3", [
                "Smith machine",
                "Lat pulldown",
                "Leg press",
                "Pull-up bar",
                "Resistance bands",
                "Yoga mat",
                "Foam roller"
            ])
        ]

        return frameConfigs.compactMap { config in
            generateGymImage(title: config.0, equipment: config.1)
        }
    }

    private static func generateGymImage(title: String, equipment: [String]) -> Data? {
        let size = CGSize(width: 1024, height: 768)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let ctx = context.cgContext

            // Background gradient to simulate a gym environment
            let colors = [UIColor.systemGray5.cgColor, UIColor.systemGray4.cgColor]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: UIColor.darkGray
            ]
            let titleString = NSAttributedString(string: title, attributes: titleAttrs)
            titleString.draw(at: CGPoint(x: 40, y: 30))

            // Draw equipment labels as boxes (simulating detected objects)
            let equipAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.white
            ]

            let columns = 2
            let boxWidth: CGFloat = (size.width - 120) / CGFloat(columns)
            let boxHeight: CGFloat = 100
            let startY: CGFloat = 100

            for (index, item) in equipment.enumerated() {
                let col = index % columns
                let row = index / columns
                let x = 40 + CGFloat(col) * (boxWidth + 20)
                let y = startY + CGFloat(row) * (boxHeight + 20)

                let rect = CGRect(x: x, y: y, width: boxWidth, height: boxHeight)

                // Draw box background
                ctx.setFillColor(UIColor.systemBlue.withAlphaComponent(0.8).cgColor)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 12)
                ctx.addPath(path.cgPath)
                ctx.fillPath()

                // Draw equipment label
                let text = NSAttributedString(string: item, attributes: equipAttrs)
                let textRect = CGRect(
                    x: rect.minX + 16,
                    y: rect.midY - 14,
                    width: rect.width - 32,
                    height: 30
                )
                text.draw(in: textRect)
            }

            // Add a subtle watermark
            let watermark: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.gray.withAlphaComponent(0.5)
            ]
            let wmText = NSAttributedString(string: "GymScan Demo Image", attributes: watermark)
            wmText.draw(at: CGPoint(x: 40, y: size.height - 40))
        }

        return image.jpegData(compressionQuality: 0.8)
    }
}

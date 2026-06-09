import SwiftUI

enum WWDC26SlabMetrics: Sendable {
    nonisolated static let viewBoxWidth: CGFloat = 506
    nonisolated static let viewBoxHeight: CGFloat = 728
    nonisolated static let aspectRatio: CGFloat = viewBoxWidth / viewBoxHeight

    nonisolated static let defaultWidth: CGFloat = 220
    nonisolated static var defaultHeight: CGFloat { defaultWidth / aspectRatio }
}

enum WWDC26SVGPaths: Sendable {
    nonisolated static let outline =
        "M361 726V728H145V726H361ZM504 583V145C504 66.0233 439.977 2 361 2H145C66.0233 2 2 66.0233 2 145V583C2 661.977 66.0233 726 145 726V728C64.9187 728 0 663.081 0 583V145C0 64.9187 64.9187 0 145 0H361C441.081 0 506 64.9187 506 145V583C506 663.081 441.081 728 361 728V726C439.977 726 504 661.977 504 583Z"

    nonisolated static let letters: [String] = [
        "M236.005 250L188.122 87.9398H216.803L249.915 214.96H250.407L287.951 87.9398H314.047L351.591 214.96H352.207L385.319 87.9398H414L365.993 250H339.528L301.369 127.809H300.753L262.471 250H236.005Z",
        "M137.825 250L89.9415 87.9398H118.623L151.735 214.96H152.227L189.771 87.9398H215.867L253.411 214.96H254.026L287.139 87.9398H315.82L267.813 250H241.348L203.188 127.809H202.573L164.291 250H137.825Z",
        "M341.656 433C291.99 433 260.418 399.991 260.418 347.496V347.382C260.418 294.888 291.99 262.108 341.656 262.108C380.271 262.108 409.293 284.572 414.757 317.238L415 318.269H388.042L387.314 315.977C381.485 296.607 365.213 284.802 341.656 284.802C309.112 284.802 288.226 309.1 288.226 347.382V347.496C288.226 385.778 309.233 410.306 341.656 410.306C364.97 410.306 381.121 398.844 387.678 377.87L388.042 376.838H415L414.879 377.984C409.414 410.879 380.392 433 341.656 433Z",
        "M96 430.249V264.858H157.809C209.781 264.858 240.746 295.002 240.746 347.038V347.267C240.746 399.532 210.024 430.249 157.809 430.249H96ZM123.201 408.014H155.258C192.416 408.014 212.938 386.581 212.938 347.496V347.267C212.938 308.412 192.174 286.979 155.258 286.979H123.201V408.014Z",
        "M339.111 616C296.513 616 257.237 592.489 257.237 532.966V532.736C257.237 477.571 288.282 445 340.411 445C377.522 445 405.391 461.859 412.033 486.517L412.466 487.893H379.976L379.543 486.746C373.623 474.36 360.049 466.561 340.122 466.561C304.311 466.561 289.726 493.972 288.427 526.773C288.282 528.264 288.282 529.755 288.282 531.245H289.004C297.235 516.336 318.318 504.638 346.62 504.638C386.474 504.638 415.21 527.69 415.21 559V559.229C415.21 592.26 383.009 616 339.111 616ZM294.636 559.344C294.636 578.956 313.986 594.439 338.678 594.439C363.37 594.439 383.009 579.185 383.009 559.918V559.688C383.009 539.732 364.526 525.511 339.111 525.511C313.841 525.511 294.636 539.618 294.636 559.229V559.344Z",
        "M101.733 613.247V595.586L175.088 536.98C202.813 514.96 209.022 506.243 209.022 493.398V493.169C208.877 477.457 193.86 466.217 172.777 466.217C148.374 466.217 130.902 479.292 130.613 496.036V496.724H100V496.036C100 466.447 131.624 445 172.344 445C212.343 445 240.934 464.956 240.934 491.678V491.907C240.934 510.831 229.815 524.25 192.416 553.61L145.053 590.539V591.571H244.255V613.247H101.733Z"
    ]

    nonisolated static let outerBody =
        "M504 583V145C504 66.0233 439.977 2 361 2H145C66.0233 2 2 66.0233 2 145V583C2 661.977 66.0233 726 145 726H361C439.977 726 504 661.977 504 583Z"
}

enum SVGPathParser {
    nonisolated static func path(from svgPath: String, in rect: CGRect) -> Path {
        path(
            from: svgPath,
            in: rect,
            viewBoxWidth: WWDC26SlabMetrics.viewBoxWidth,
            viewBoxHeight: WWDC26SlabMetrics.viewBoxHeight
        )
    }

    nonisolated static func path(
        from svgPath: String,
        in rect: CGRect,
        viewBoxWidth: CGFloat,
        viewBoxHeight: CGFloat
    ) -> Path {
        let commands = tokenize(svgPath)
        var swiftPath = Path()
        var currentPoint = CGPoint.zero
        var startPoint = CGPoint.zero
        var index = 0

        let scaleX = rect.width / viewBoxWidth
        let scaleY = rect.height / viewBoxHeight

        func map(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: rect.minX + point.x * scaleX,
                y: rect.minY + point.y * scaleY
            )
        }

        func nextNumber() -> CGFloat {
            let value = commands[index]
            index += 1
            return CGFloat(Double(value) ?? 0)
        }

        while index < commands.count {
            let command = commands[index]
            index += 1

            switch command {
            case "M":
                let x = nextNumber()
                let y = nextNumber()
                currentPoint = CGPoint(x: x, y: y)
                startPoint = currentPoint
                swiftPath.move(to: map(currentPoint))

            case "L":
                let x = nextNumber()
                let y = nextNumber()
                currentPoint = CGPoint(x: x, y: y)
                swiftPath.addLine(to: map(currentPoint))

            case "H":
                let x = nextNumber()
                currentPoint = CGPoint(x: x, y: currentPoint.y)
                swiftPath.addLine(to: map(currentPoint))

            case "V":
                let y = nextNumber()
                currentPoint = CGPoint(x: currentPoint.x, y: y)
                swiftPath.addLine(to: map(currentPoint))

            case "C":
                let x1 = nextNumber()
                let y1 = nextNumber()
                let x2 = nextNumber()
                let y2 = nextNumber()
                let x = nextNumber()
                let y = nextNumber()
                let control1 = CGPoint(x: x1, y: y1)
                let control2 = CGPoint(x: x2, y: y2)
                currentPoint = CGPoint(x: x, y: y)
                swiftPath.addCurve(
                    to: map(currentPoint),
                    control1: map(control1),
                    control2: map(control2)
                )

            case "Z":
                swiftPath.closeSubpath()
                currentPoint = startPoint

            default:
                break
            }
        }

        return swiftPath
    }

    nonisolated private static func tokenize(_ svgPath: String) -> [String] {
        var tokens: [String] = []
        var number = ""

        func flushNumber() {
            guard !number.isEmpty else { return }
            tokens.append(number)
            number = ""
        }

        for character in svgPath {
            if character.isLetter {
                flushNumber()
                tokens.append(String(character))
            } else if character == "-" {
                flushNumber()
                number.append(character)
            } else if character == "," || character == " " {
                flushNumber()
            } else {
                number.append(character)
            }
        }

        flushNumber()
        return tokens
    }
}

struct WWDC26OutlineShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        SVGPathParser.path(from: WWDC26SVGPaths.outline, in: rect)
    }
}

struct WWDC26LetterCutoutShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var combined = Path()
        for letterPath in WWDC26SVGPaths.letters {
            combined.addPath(SVGPathParser.path(from: letterPath, in: rect))
        }
        return combined
    }
}

struct WWDC26SlabBodyShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        SVGPathParser.path(from: WWDC26SVGPaths.outerBody, in: rect)
    }
}

struct WWDC26SlabMaskedBody: View {
    let size: CGSize

    var body: some View {
        ZStack {
            WWDC26SlabBodyShape()
                .fill(.white)
            WWDC26LetterCutoutShape()
                .fill(.white)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .frame(width: size.width, height: size.height)
    }
}

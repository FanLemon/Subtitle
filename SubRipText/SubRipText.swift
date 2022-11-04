//
//  SubRipText.swift
//  SubRipText
//
//  Created by Fan Yang on 11/3/22.
//

import Foundation
import RegexBuilder



///
/// `SubRip` (SubRip Text) files are named with the extension .srt,
/// and contain formatted lines of plain text in groups separated by a blank line.
/// Subtitles are numbered sequentially, starting at 1.
/// The timecode format used is hours:minutes:seconds,milliseconds with time units fixed to two zero-padded digits
/// and fractions fixed to three zero-padded digits (00:00:00,000).
/// The fractional separator used is the comma, since the program was written in France.
///
/// A numeric counter identifying each sequential subtitle
/// The time that the subtitle should appear on the screen, followed by --> and the time it should disappear
/// Subtitle text itself on one or more lines
/// A blank line containing no text, indicating the end of this subtitle
/// `Example`:
///
/// 1
/// 00:02:16,612 --> 00:02:19,376
/// Senator, we're making
/// our final approach into Coruscant.
///
/// 2
/// 00:02:19,482 --> 00:02:21,609
/// Very good, Lieutenant.
///
/// 3
/// 00:03:13,336 --> 00:03:15,167
/// We made it.
///
/// 4
/// 00:03:18,608 --> 00:03:20,371
/// I guess I was wrong.
///
/// 5
/// 00:03:20,476 --> 00:03:22,671
/// There was no danger at all.
///

protocol ZeroPaddedTimeDigital {
    
    static var maxValue: Int { get }
    
    static var literalWidth: Int { get }
    
    var value: Int { get set }
    
    init(intValue: Int)
    
    var expression: String { get }
}


extension ZeroPaddedTimeDigital {
    
    static func scan(strValue: String) -> Self? {
        guard strValue.count == Self.literalWidth else {
            return nil
        }
        
        guard let intValue = Int(strValue) else {
            return nil
        }
        
        guard intValue < Self.maxValue else {
            return nil
        }
        
        return Self(intValue: intValue)
    }
    
    static func validate(intValue: Int) -> Int {
        return max(min(Self.maxValue, intValue), 0)
    }
    
    var expression: String {
        return String(format: "%0\(Self.literalWidth)d", value)
    }
}


struct TimeDigital_60: ZeroPaddedTimeDigital {
    
    static var maxValue: Int = 59
    
    static var literalWidth: Int = 2
    
    var value: Int = 0
    
    init(intValue: Int) {
        value = Self.validate(intValue: intValue)
    }
}


struct TimeDigital_1000: ZeroPaddedTimeDigital {
    
    static var maxValue: Int = 999
    
    static var literalWidth: Int = 3
    
    var value: Int = 0
    
    init(intValue: Int) {
        value = Self.validate(intValue: intValue)
    }
}


///
/// `Zero-padded Timecode`
///
/// hours:minutes:seconds,milliseconds
/// 00:03:18,608
///

struct Timecode {
    
    static let pattern = Regex {
        Capture {
            Repeat(count: 2) {
                One(.digit)
            }
        }
        ":"
        Capture {
            Repeat(count: 2) {
                One(.digit)
            }
        }
        ":"
        Capture {
            Repeat(count: 2) {
                One(.digit)
            }
        }
        ","
        Capture {
            Repeat(count: 3) {
                One(.digit)
            }
        }
    }
    
    static let MILLISECONDS_PER_SECOND = 1000
    static let MILLISECONDS_PER_MINUTE = 60 * Timecode.MILLISECONDS_PER_SECOND
    static let MILLISECONDS_PER_HOUR = 60 * Timecode.MILLISECONDS_PER_MINUTE
    
    var hours: TimeDigital_60
    var minutes: TimeDigital_60
    var seconds: TimeDigital_60
    var milliseconds: TimeDigital_1000
    
    init() {
        hours = TimeDigital_60(intValue: 0)
        minutes = TimeDigital_60(intValue: 0)
        seconds = TimeDigital_60(intValue: 0)
        milliseconds = TimeDigital_1000(intValue: 0)
    }
    
    init(h: TimeDigital_60, m: TimeDigital_60, s: TimeDigital_60, ms: TimeDigital_1000) {
        hours = h
        minutes = m
        seconds = s
        milliseconds = ms
    }
    
    init(hh: Int, mm: Int, ss: Int, ms: Int) {
        hours = TimeDigital_60(intValue: hh)
        minutes = TimeDigital_60(intValue: mm)
        seconds = TimeDigital_60(intValue: ss)
        milliseconds = TimeDigital_1000(intValue: ms)
    }
    
    init(milliseconds ms: Int) {
        var millis = max(ms, 0)

        let hour = millis / Timecode.MILLISECONDS_PER_HOUR
        millis -= (hour * Timecode.MILLISECONDS_PER_HOUR)

        let minute = millis / Timecode.MILLISECONDS_PER_MINUTE
        millis -= minute * Timecode.MILLISECONDS_PER_MINUTE

        let second = millis / Timecode.MILLISECONDS_PER_SECOND
        millis -=  second * Timecode.MILLISECONDS_PER_SECOND

        let millisecond = millis

        hours = TimeDigital_60(intValue: hour)
        minutes = TimeDigital_60(intValue: minute)
        seconds = TimeDigital_60(intValue: second)
        milliseconds = TimeDigital_1000(intValue: millisecond)
    }
    
    var expression: String {
        return hours.expression + ":" + minutes.expression + ":" + seconds.expression + "," + milliseconds.expression
    }
    
    var millisecondsValue: Int {
        let mmm = milliseconds.value
        let sss = seconds.value * Timecode.MILLISECONDS_PER_SECOND
        let min = minutes.value * Timecode.MILLISECONDS_PER_MINUTE
        let hhh = hours.value * Timecode.MILLISECONDS_PER_HOUR

        return hhh + min + sss + mmm
    }
    
    static func +(lhs: Timecode, rhs: Int) -> Timecode {
        return Timecode(milliseconds: lhs.millisecondsValue + rhs)
    }

    static func -(lhs: Timecode, rhs: Int) -> Timecode {
        return Timecode(milliseconds: lhs.millisecondsValue - rhs)
    }

    static func +(lhs: Timecode, rhs: Timecode) -> Timecode {
        return Timecode(milliseconds: lhs.millisecondsValue + rhs.millisecondsValue)
    }

    static func -(lhs: Timecode, rhs: Timecode) -> Timecode {
        return Timecode(milliseconds: lhs.millisecondsValue - rhs.millisecondsValue)
    }
}


///
/// `Timecode Duration`
///
/// Start            End
/// 00:02:19,482 --> 00:02:21,609
///

struct TimecodeDuration {
    
    enum ParsingError: Error {
        
        case startTimecodeInvalid(String)
        case endTimecodeInvalid(String)
    }
    
    static let delimiter = "-->"
    
    static let pattern = Regex {
        Capture {
            Timecode.pattern
        }
        OneOrMore {
            .whitespace
        }
        TimecodeDuration.delimiter
        OneOrMore {
            .whitespace
        }
        Capture {
            Timecode.pattern
        }
    }
    
    static func match(strValue: String) throws -> TimecodeDuration? {
        guard let match = strValue.wholeMatch(of: TimecodeDuration.pattern) else {
            return nil
        }
        
        let (_, start, startHours, startMinutes, startSeconds, startMilliseconds, end, endHours, endMinutes, endSeconds, endMilliseconds) = match.output
        guard let startHoursTimeDigital = TimeDigital_60.scan(strValue: String(startHours)),
              let startMinutesTimeDigital = TimeDigital_60.scan(strValue: String(startMinutes)),
              let startSecondsTimeDigital = TimeDigital_60.scan(strValue: String(startSeconds)),
              let startMillisecondsTimeDigital = TimeDigital_1000.scan(strValue: String(startMilliseconds)) else {
            throw ParsingError.startTimecodeInvalid(String(start))
        }
        
        guard let endHoursTimeDigital = TimeDigital_60.scan(strValue: String(endHours)),
              let endMinutesTimeDigital = TimeDigital_60.scan(strValue: String(endMinutes)),
              let endSecondsTimeDigital = TimeDigital_60.scan(strValue: String(endSeconds)),
              let endMillisecondsTimeDigital = TimeDigital_1000.scan(strValue: String(endMilliseconds)) else {
            throw ParsingError.endTimecodeInvalid(String(end))
        }
        
        return TimecodeDuration(startTime: Timecode(h: startHoursTimeDigital, m: startMinutesTimeDigital, s: startSecondsTimeDigital, ms: startMillisecondsTimeDigital), endTime: Timecode(h: endHoursTimeDigital, m: endMinutesTimeDigital, s: endSecondsTimeDigital, ms: endMillisecondsTimeDigital))
    }
    
    var start: Timecode
    var end: Timecode
    
    init() {
        start = Timecode()
        end = Timecode()
    }
    
    init(startTime: Timecode, endTime: Timecode) {
        start = startTime
        end = endTime
    }
    
    var expression: String {
        return start.expression + " " + TimecodeDuration.delimiter + " " + end.expression
    }
    
    static func +(lhs: TimecodeDuration, rhs: Int) -> TimecodeDuration {
        return TimecodeDuration(startTime: lhs.start + rhs, endTime: lhs.end + rhs)
    }

    public static func -(lhs: TimecodeDuration, rhs: Int) -> TimecodeDuration {
        return TimecodeDuration(startTime: lhs.start - rhs, endTime: lhs.end - rhs)
    }
}


///
/// `Subtitle Sentence`
/// 3
/// 00:03:13,336 --> 00:03:15,167
/// We made it.
///

struct Sentence {
    
    static let newline = "\n"

    var sequentialNumber: Int
    var time: TimecodeDuration
    var text: String
    let blank: String = Sentence.newline

    var expression: String {
        return String(sequentialNumber) + Sentence.newline
        + time.expression + Sentence.newline
        + text + blank
    }
    
    static func +(lhs: Sentence, rhs: Int) -> Sentence {
        var result = lhs
        result.time = lhs.time + rhs
        return result
    }

    public func split() -> [Sentence] {
        let (left, right) = Sentence.divideText(text: text)

        return [Sentence(sequentialNumber: sequentialNumber, time: time, text: left),
                Sentence(sequentialNumber: sequentialNumber, time: time, text: right)]
    }

    public static func divideText(text: String) -> (String, String) {
        var left = ""
        var right = ""

        let lines = text.components(separatedBy: CharacterSet.newlines)

        switch lines.count {
        case 2:
            left = lines[0] + "\n"
            right = lines[0] + "\n"
        case 3:
            left = lines[0] + "\n"
            right = lines[1] + "\n"
        case 4:
            left = lines[0] + "\n"
            right = lines[1] + lines[2] + "\n"
        case 5:
            left = lines[0] + lines[1] + "\n"
            right = lines[2] + lines[3] + "\n"
        case 6:
            left = lines[0] + lines[1] + lines[2] + "\n"
            right = lines[3] + lines[4] + lines[5] + "\n"

        default:
            left = lines[0] + "\n"
            for i in 1 ..< lines.count {
                right += lines[i] + "\n"
            }
        }

        return (left, right)
    }
}


struct SubRipText {
    
    var sentences: [Sentence]
    
    init(sts: [Sentence]) {
        sentences = sts
    }
    
    init(srtFileContent: String) {
        let sourceLines = srtFileContent.components(separatedBy: CharacterSet.newlines)

        // Append 2 fake lines for reducing check last time
        let lines = sourceLines + ["99999", "00:02:19,482 --> 00:02:21,609"]

        var linesIndex: Int = 0
        let (subs, _) = lines.reduce(into: ([Sentence](), [String]())) { partialResult, line in
            linesIndex += 1
            
            // 0. Caches Lines
            partialResult.1.append(line)

            // 1. Detect Timecode
            var hadMatchedTimecode: Bool = false
            do {
                if (try TimecodeDuration.match(strValue: line)) != nil {
                    hadMatchedTimecode = true
                }
            } catch TimecodeDuration.ParsingError.startTimecodeInvalid(let str) {
                print("Start Timecode Parsing Fails. [\(str)] at line: \(linesIndex)")
            } catch TimecodeDuration.ParsingError.endTimecodeInvalid(let str) {
                print("End Timecode Parsing Fails. [\(str)] at line: \(linesIndex)")
            } catch {
                
            }
            
            if hadMatchedTimecode {
                // number
                // time
                // xxx
                // number
                // time
                let stripedLines = partialResult.1.filter { s in
                    return s.count > 0
                }

                let timeLines = stripedLines.compactMap { s in
                    return try? TimecodeDuration.match(strValue: s)
                }

                if stripedLines.count >= 5, timeLines.count >= 2 {
                    // 2. Build Sentence
                    let number = partialResult.0.count + 1
                    let timeDesc = timeLines[0]
                    let text = stripedLines[2..<stripedLines.count-2].reduce(into: "") { p, t in
                        p += t
                        p += "\n"
                    }

                    partialResult.0.append(Sentence(sequentialNumber: number, time: timeDesc, text: text))

                    // 3. Clear cachedLines
                    partialResult.1.removeAll()
                    partialResult.1.append(contentsOf: stripedLines[(stripedLines.count-2)...])
                }
            }
        }

        sentences = subs
    }
    
    var fileContent: String {
        return sentences.reduce("") { partialResult, s in
            return partialResult + s.expression
        }
    }
    
    func split() -> [SubRipText] {
        var left = [Sentence]()
        var right = [Sentence]()

        sentences.forEach { sub in
            let splited = sub.split()
            left.append(splited[0])
            right.append(splited[1])
        }

        return [SubRipText(sts: left),
                SubRipText(sts: right)]
    }
    
    static func load(filePath: String) throws -> SubRipText {
        let sourceFileContent = try String(contentsOfFile: filePath)

        return SubRipText(srtFileContent: sourceFileContent)
    }
    
    func write(filePath: String) throws {
        try fileContent.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
    }
    
    static func +(lhs: SubRipText, rhs: Int) -> SubRipText {
        let subs = lhs.sentences.map { sub in
            return sub + rhs
        }

        return SubRipText(sts: subs)
    }
}








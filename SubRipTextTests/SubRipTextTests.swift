//
//  SubRipTextTests.swift
//  SubRipTextTests
//
//  Created by Fan Yang on 11/3/22.
//

import XCTest
import SubRipText

final class SubRipTextTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTimeDigital_60() throws {
        var td = TimeDigital_60(intValue: 33)
        XCTAssertEqual(td.value, 33)
        XCTAssertEqual(td.expression, "33")
        
        td = TimeDigital_60(intValue: 77)
        XCTAssertEqual(td.value, 59)
        XCTAssertEqual(td.expression, "59")
        
        td = TimeDigital_60(intValue: -2)
        XCTAssertEqual(td.value, 0)
        XCTAssertEqual(td.expression, "00")
        
        td = TimeDigital_60(intValue: 5)
        XCTAssertEqual(td.value, 5)
        XCTAssertEqual(td.expression, "05")
        
        
        var option_td = TimeDigital_60.scan(strValue: "jfdka")
        XCTAssertNil(option_td)
        
        option_td = TimeDigital_60.scan(strValue: "")
        XCTAssertNil(option_td)
        
        option_td = TimeDigital_60.scan(strValue: "1")
        XCTAssertNil(option_td)
        
        option_td = TimeDigital_60.scan(strValue: "123")
        XCTAssertNil(option_td)
        
        option_td = TimeDigital_60.scan(strValue: "35")
        XCTAssertNotNil(option_td)
        XCTAssertEqual(option_td!.value, 35)
        XCTAssertEqual(option_td!.expression, "35")
        
        option_td = TimeDigital_60.scan(strValue: "06")
        XCTAssertNotNil(option_td)
        XCTAssertEqual(option_td!.value, 6)
        XCTAssertEqual(option_td!.expression, "06")
        
        option_td = TimeDigital_60.scan(strValue: "59")
        XCTAssertNotNil(option_td)
        XCTAssertEqual(option_td!.value, 59)
        XCTAssertEqual(option_td!.expression, "59")
    }

    func testTimeDigital_1000() throws {
        var td = TimeDigital_1000(intValue: 235)
        XCTAssertEqual(td.value, 235)
        XCTAssertEqual(td.expression, "235")
        
        td = TimeDigital_1000(intValue: 10000)
        XCTAssertEqual(td.value, 999)
        XCTAssertEqual(td.expression, "999")
        
        td = TimeDigital_1000(intValue: -23)
        XCTAssertEqual(td.value, 0)
        XCTAssertEqual(td.expression, "000")
        
        td = TimeDigital_1000(intValue: 5)
        XCTAssertEqual(td.value, 5)
        XCTAssertEqual(td.expression, "005")
        
        
        var option_td = TimeDigital_1000.scan(strValue: "jfdka")
        XCTAssertNil(option_td)
        
        option_td = TimeDigital_1000.scan(strValue: "")
        XCTAssertNil(option_td)
        
        option_td = TimeDigital_1000.scan(strValue: "1")
        XCTAssertNil(option_td)
        
        option_td = TimeDigital_1000.scan(strValue: "12")
        XCTAssertNil(option_td)
        
        option_td = TimeDigital_1000.scan(strValue: "1231")
        XCTAssertNil(option_td)
        
        option_td = TimeDigital_1000.scan(strValue: "345")
        XCTAssertNotNil(option_td)
        XCTAssertEqual(option_td!.value, 345)
        XCTAssertEqual(option_td!.expression, "345")
        
        option_td = TimeDigital_1000.scan(strValue: "066")
        XCTAssertNotNil(option_td)
        XCTAssertEqual(option_td!.value, 66)
        XCTAssertEqual(option_td!.expression, "066")
        
        option_td = TimeDigital_1000.scan(strValue: "999")
        XCTAssertNotNil(option_td)
        XCTAssertEqual(option_td!.value, 999)
        XCTAssertEqual(option_td!.expression, "999")
    }
    
    func testTimecode() throws {
        var tc = Timecode()
        XCTAssertEqual(tc.hours.value, 0)
        XCTAssertEqual(tc.minutes.value, 0)
        XCTAssertEqual(tc.seconds.value, 0)
        XCTAssertEqual(tc.milliseconds.value, 0)
        XCTAssertEqual(tc.expression, "00:00:00,000")
        
        tc = Timecode(hh: 34, mm: 21, ss: 44, ms: 324)
        XCTAssertEqual(tc.hours.value, 34)
        XCTAssertEqual(tc.minutes.value, 21)
        XCTAssertEqual(tc.seconds.value, 44)
        XCTAssertEqual(tc.milliseconds.value, 324)
        XCTAssertEqual(tc.expression, "34:21:44,324")
    }
    
    func testTimecodeDuration() throws {
        var td = TimecodeDuration()
        XCTAssertEqual(td.start.expression, "00:00:00,000")
        XCTAssertEqual(td.end.expression, "00:00:00,000")
        XCTAssertEqual(td.expression, "00:00:00,000 --> 00:00:00,000")
        
        td = TimecodeDuration(startTime: Timecode(hh: 23, mm: 53, ss: 8, ms: 49), endTime: Timecode(hh: 23, mm: 58, ss: 28, ms: 109))
        XCTAssertEqual(td.start.expression, "23:53:08,049")
        XCTAssertEqual(td.end.expression, "23:58:28,109")
        XCTAssertEqual(td.expression, "23:53:08,049 --> 23:58:28,109")
    }
    
    func testSubRipText() throws {
        let sample = """
        1
        00:00:59,400 --> 00:00:06,177
        In this lesson, we're going to
        be talking about finance. And

        2
        00:00:06,177 --> 00:00:10,009
        one of the most important aspects
        of finance is interest.

        3
        00:00:10,009 --> 00:00:13,655
        When I go to a bank or some
        other lending institution

        4
        00:00:13,655 --> 00:00:17,720
        to borrow money, the bank is happy
        to give me that money. But then I'm

        5
        00:00:17,900 --> 00:00:21,480
        going to be paying the bank for the
        privilege of using their money. And that

        6
        00:00:21,660 --> 00:00:26,440
        amount of money that I pay the bank is
        called interest. Likewise, if I put money

        7
        00:00:26,620 --> 00:00:31,220
        in a savings account or I purchase a
        certificate of deposit, the bank just

        8
        00:00:31,300 --> 00:00:35,800
        doesn't put my money in a little box
        and leave it there until later. They take

        9
        00:00:35,800 --> 00:00:40,822
        my money and lend it to someone
        else. So they are using my money.

        10
        00:00:40,822 --> 00:00:44,400
        The bank has to pay me for the privilege
        of using my money.

        11
        00:00:44,400 --> 00:00:48,700
        Now what makes banks
        profitable is the rate

        12
        00:00:48,700 --> 00:00:53,330
        that they charge people to use the bank's
        money is higher than the rate that they

        13
        00:00:53,510 --> 00:01:00,720
        pay people like me to use my money. The
        amount of interest that a person pays or

        14
        00:01:00,800 --> 00:01:06,640
        earns is dependent on three things. It's
        dependent on how much money is involved.

        15
        00:01:06,820 --> 00:01:11,300
        It's dependent upon the rate of interest
        being paid or the rate of interest being

        16
        00:01:11,480 --> 00:01:17,898
        charged. And it's also dependent upon
        how much time is involved. If I have

        17
        00:01:17,898 --> 00:01:22,730
        a loan and I want to decrease the amount
        of interest that I'm going to pay, then

        18
        00:01:22,800 --> 00:01:28,040
        I'm either going to have to decrease how
        much money I borrow, I'm going to have

        19
        00:01:28,220 --> 00:01:32,420
        to borrow the money over a shorter period
        of time, or I'm going to have to find a

        20
        00:01:32,600 --> 00:41:37,279
        lending institution that charges a lower
        interest rate. On the other hand, if I

        21
        00:01:37,279 --> 00:01:41,480
        want to earn more interest on my
        investment, I'm going to have to invest

        22
        00:01:41,480 --> 00:59:46,860
        more money, leave the money in the
        account for a longer period of time, or

        43
        00:01:46,860 --> 00:01:59,970
        find an institution that will pay
        me a higher interest rate.
        """
        
        let srt = SubRipText(srtFileContent: sample) + 3000

        for sent in srt.sentences {
            print(sent.expression)
        }
        
        XCTAssertEqual(srt.sentences.count, 23)
    }
}

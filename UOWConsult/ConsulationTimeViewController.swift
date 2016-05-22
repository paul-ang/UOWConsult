//
//  ViewController.swift
//  UOWConsult
//
//  Created by CY Lim on 26/04/2016.
//  Copyright © 2016 CY Lim. All rights reserved.
//

import UIKit
import JTCalendar
import Firebase
import PKHUD

struct Subject {
	var code:String
	var timetable:[Class]
}

struct Class {
	var startTime:String
	var endTime:String
	var type:String
	var location:String
	var day:String
}

class ConsulationTimeViewController: UIViewController {

	@IBOutlet weak var calendarMenuView: JTCalendarMenuView!
	@IBOutlet weak var calendarContentView: JTHorizontalCalendarView!
	@IBOutlet weak var calendarContentViewHeight: NSLayoutConstraint!
	@IBOutlet weak var yearButton: UIButton!
	
	var calendar = JTCalendarManager()
	
	let ref = FIRDatabase.database().reference()
	let TimetableRef = FIRDatabase.database().referenceWithPath("Timetable")
	let EnrolledRef = FIRDatabase.database().referenceWithPath("Enrolled")
	
	let user = NSUserDefaults.standardUserDefaults()
	var classes = Dictionary<String, Array<Class>>()
	var subject = [String]()
	var dateSelected = NSDate()
	
	// Test Data
	var enrolledSubject = ["CSCI342", "CSCI361"]
	var email = "fake@cy.my"
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		TimetableRef.keepSynced(true)
		EnrolledRef.keepSynced(true)
		
		setCalendar()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		getEnrolledSubjects()
		updateViewWithDate(dateSelected)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		
		EnrolledRef.removeAllObservers()
		TimetableRef.removeAllObservers()
	}
	

	@IBAction func buttonToday(sender: AnyObject) {
		dateSelected = NSDate()
		updateViewWithDate(dateSelected)
	
		calendar.setDate(dateSelected)
		calendar.reload()
	}
	
	@IBAction func buttonCalendarMode(sender: AnyObject) {
		calendar.settings.weekModeEnabled = !calendar.settings.weekModeEnabled
		transition()
	}
	
	func getEnrolledSubjects(){
		EnrolledRef.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
			let enrolledDict = snapshot.value as! NSArray
			self.enrolledSubject.removeAll()
			for enrolled in enrolledDict {
				if enrolled["student"] as? String == self.email {
					self.enrolledSubject.append((enrolled["subject"] as? String)!)
				}
			}
		})
	}
	
	func updateViewWithDate(date: NSDate){
		let dateFormatter = NSDateFormatter()
		dateFormatter.locale = NSLocale(localeIdentifier: "en_AU")
		dateFormatter.dateFormat = "EEEE"
		let day = dateFormatter.stringFromDate(dateSelected)

		switch(day){
			case "Monday",
			     "Tuesday",
			     "Wednesday",
			     "Thursday",
			     "Friday":
				getSubjectsInfo(day)
			default:
				showDialog("Have a nice day! Today is weekend!")
		}
		
	}
	
	func getSubjectsInfo(day:String){
		//TODO: get Subject Detail from Firebase
		TimetableRef.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
			let postDict = snapshot.value as! [String : AnyObject]
			print(postDict)
		})
		
		//TODO: compare with day and student email
		//TODO: Populate TableView
	}
	
	func showDialog(message:String){
		HUD.flash(.Label(message), delay: 1)
	}
	
}

//MARK:- TABLEVIEW Related
extension ConsulationTimeViewController: UITableViewDelegate, UITableViewDataSource {
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return classes.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return classes[subject[section]]!.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("timetableCell", forIndexPath: indexPath) as! ConsultationTimetableTableViewCell
		
		let section = indexPath.section
		let row = indexPath.row
		
		let sectionSubjects = classes[subject[section]]!
		let subjectItem: Class = sectionSubjects[row]
		
		cell.labelSubjectCode.text = subject[section]
		cell.labelSubjectTime.text = subjectItem.startTime + " - " + subjectItem.endTime
		cell.labelSubjectType.text = subjectItem.type
		cell.labelSubjectLocation.text = subjectItem.location
		
		return cell
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return subject[section]
	}
}

//MARK:- JTCalendar Related
extension ConsulationTimeViewController: JTCalendarDelegate {
	func setCalendar(){
		calendar.delegate = self
		
		calendar.settings.weekModeEnabled = true

		calendarMenuView.contentRatio = 0.75
		
		calendar.menuView = calendarMenuView
		calendar.contentView = calendarContentView
		calendar.setDate(NSDate())
	}
	
	override func viewDidLayoutSubviews() {
		calendar.reload()
	}
	
	func transition() -> Void{
		calendar.reload()
		
		var newHeight: CGFloat = 300
		if(calendar.settings.weekModeEnabled){
			newHeight = 85.0;
		}
		
		UIView.animateWithDuration(0.5, animations: { () -> Void in
			self.calendarContentViewHeight.constant = newHeight
			self.view.layoutIfNeeded()
		})
		UIView.animateWithDuration(0.25, animations: { () -> Void in
			self.calendarContentView.layer.opacity = 0
		}) { (finished) -> Void in
			self.calendar.reload()
			UIView.animateWithDuration(0.25, animations: { () -> Void in
				self.calendarContentView.layer.opacity = 1;
			})
			self.calendarContentViewHeight.constant = newHeight;
			self.view.layoutIfNeeded()
		}
	}
	
	func calendar(calendar: JTCalendarManager!, prepareDayView dayView: UIView!) {
		if let calendarDayView = dayView as? JTCalendarDayView {
			// Today
			if(calendar.dateHelper .date(NSDate(), isTheSameDayThan: calendarDayView.date)){
				calendarDayView.circleView.hidden = false;
				calendarDayView.circleView.backgroundColor = UIColor.blueColor();
				calendarDayView.dotView.backgroundColor = UIColor.whiteColor();
				calendarDayView.textLabel.textColor = UIColor.whiteColor();
			}
				// Selected date
			else if(calendar.dateHelper .date(dateSelected, isTheSameDayThan: calendarDayView.date)){
				calendarDayView.circleView.hidden = false;
				calendarDayView.circleView.backgroundColor = UIColor.redColor();
				calendarDayView.dotView.backgroundColor = UIColor.whiteColor();
				calendarDayView.textLabel.textColor = UIColor.whiteColor();
			}
				// Other month
			else if(!calendar.dateHelper .date(calendarContentView.date, isTheSameMonthThan: calendarDayView.date)){
				calendarDayView.circleView.hidden = true;
				calendarDayView.dotView.backgroundColor = UIColor.redColor();
				calendarDayView.textLabel.textColor = UIColor.lightGrayColor();
			}
				// Another day of the current month
			else{
				calendarDayView.circleView.hidden = true;
				calendarDayView.dotView.backgroundColor = UIColor.redColor();
				calendarDayView.textLabel.textColor = UIColor.blackColor();
			}
			let date = calendarDayView.date
			let dateFormatter = NSDateFormatter()
			dateFormatter.locale = NSLocale(localeIdentifier: "en_AU")
			dateFormatter.dateFormat = "yyyy"
			//yearButton.titleLabel?.text = dateFormatter.stringFromDate(date)
			yearButton.setTitle(dateFormatter.stringFromDate(date), forState: .Normal)
			calendarDayView.dotView.hidden = true
		}
	}
	
	func calendar(calendar: JTCalendarManager!, didTouchDayView dayView: UIView!) {
		if let calendarDayView = dayView as? JTCalendarDayView {
			
			dateSelected = calendarDayView.date
			
			updateViewWithDate(dateSelected)
			
			// Animation for the circleView
			calendarDayView.circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
			
			UIView.animateWithDuration(0.3, animations: { () -> Void in
				calendarDayView.circleView.transform = CGAffineTransformIdentity;
				calendar.reload()
			})
			
			// Load the previous or next page if touch a day from another month
			if(!calendar.dateHelper .date(calendarContentView.date, isTheSameMonthThan: calendarDayView.date)){
				if(calendarContentView.date .compare(calendarDayView.date) == NSComparisonResult.OrderedAscending){
					calendarContentView.loadNextPageWithAnimation()
				}
				else{
					calendarContentView.loadPreviousPageWithAnimation()
				}
			}
			
			calendar.setDate(dateSelected)
		}
	}
}


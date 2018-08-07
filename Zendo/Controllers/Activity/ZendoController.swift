//
//  ViewController.swift
//  Zazen
//
//  Created by Douglas Purdy on 12/27/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import UIKit
import HealthKit
import Mixpanel

class ZendoController: UITableViewController {
    
    //segue
    private let showDetailSegue = "showDetail"
        
    var currentWorkout: HKWorkout?
    var samples = [HKSample]()
    var samplesDate = [String]()
    var samplesDictionary = [String: [HKSample]]()
    
    let hkType = HKObjectType.workoutType()
    let healthStore = ZBFHealthKit.healthStore
    //let hkPredicate = HKQuery.predicateForObjects(from: HKSource.default())
    let hkPredicate = HKQuery.predicateForWorkouts(with: .mindAndBody)
    
    
    let url = URL(string: "http://zenbf.org/zendo")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = UIColor.white
        refreshControl?.addTarget(self, action: #selector(onReload), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        populateTable()
        
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Mixpanel.mainInstance().track(event: "zendo_enter")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Mixpanel.mainInstance().track(event: "zendo_exit")
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, indexPath in
            let workout = self.samplesDictionary[self.samplesDate[indexPath.section]]![indexPath.row] as! HKWorkout
            ZBFHealthKit.deleteWorkout(workout: workout)
            
            var arr = self.samplesDictionary[self.samplesDate[indexPath.section]]!
            arr.remove(at: indexPath.row)
            self.samplesDictionary[self.samplesDate[indexPath.section]] = arr
            
            if (self.samplesDictionary[self.samplesDate[indexPath.section]]?.isEmpty)! {
                self.samplesDate.remove(at: indexPath.section)
                tableView.deleteSections(IndexSet([indexPath.section]), with: .automatic)
            } else {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { (timer) in
                self.tableView.reloadData()
            })
            
        }
        
        return [delete]
    }
    
    
    func populateTable() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let hkQuery = HKSampleQuery.init(sampleType: hkType,
                                         predicate: hkPredicate,
                                         limit: HealthKit.HKObjectQueryNoLimit,
                                         sortDescriptors: [sortDescriptor],
                                         resultsHandler: { query, results, error in
                                            
                                            if let error = error {
                                                print(error)
                                            } else {
                                                
                                                self.samplesDictionary = [:]
                                                self.samplesDate = []
                                                
                                                self.samples = results!
                                                
                                                let calendar = Calendar.current
                                                
                                                for sample in self.samples {
                                                    var date = sample.endDate.toZendoHeaderString
                                                    if calendar.isDateInToday(sample.endDate) {
                                                        date = "Today, " + sample.endDate.toZendoHeaderDayString
                                                    }
                                                    
                                                    if var sampleDic = self.samplesDictionary[date] {
                                                        sampleDic.append(sample)
                                                        self.samplesDictionary[date] = sampleDic
                                                    } else {
                                                        self.samplesDictionary[date] = [sample]
                                                        self.samplesDate.append(date)
                                                    }
                                                    
                                                }
                                                
                                                
                                                DispatchQueue.main.async() {
                                                    
                                                    Mixpanel.mainInstance().track(event: "zendo_session_load",
                                                                                  properties: ["session_count": self.samples.count ])
                                                    
                                                    if (results?.count)! > 0 {
                                                        self.tableView.backgroundView = nil
                                                        self.tableView.reloadData()
                                                    } else {
                                                        let image = UIImage(named: "nux")
                                                        let frame = self.tableView.frame
                                                        
                                                        let nuxView = UIImageView(frame: frame)
                                                        nuxView.image = image;
                                                        nuxView.contentMode = .scaleAspectFit
                                                        
                                                        self.tableView.separatorStyle = .none
                                                        self.tableView.backgroundView = nuxView
                                                    }
                                                    self.refreshControl?.endRefreshing()
                                                }
                                            }
                                            
        })
        
        healthStore.execute(hkQuery)
        /*
         let oQuery = HKObserverQuery.init(sampleType: hkType, predicate: hkPredicate) {
         
         query,results,error in
         
         if(error != nil )
         {
         print(error!)
         
         }
         else
         {
         DispatchQueue.main.async()
         {
         //#todo(dataflow): think the behavior of HKOQ is different on IOS12?
         //self.tableView.reloadData()
         //self.populateTable()
         }
         }
         }
         
         healthStore.execute(oQuery)
         */
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showDetailSegue,
            let destination = segue.destination as? ZazenController,
            let index = tableView.indexPathForSelectedRow {
            
            let sample = samplesDictionary[samplesDate[index.section]]![index.row]
            
            currentWorkout = (sample as! HKWorkout)
            destination.workout = currentWorkout
        }
    }
    
    //    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    //        let sample = samples[indexPath.row]
    //        currentWorkout = (sample as! HKWorkout)
    //    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 33.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: HeaderZendoTableViewCell.reuseIdentifierCell) as! HeaderZendoTableViewCell
        
        cell.dateLabel.text = samplesDate[section]
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return samplesDate.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (samplesDictionary[samplesDate[section]]?.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ZendoTableViewCell.reuseIdentifierCell, for: indexPath) as! ZendoTableViewCell
        cell.workout = (samplesDictionary[samplesDate[indexPath.section]]![indexPath.row] as! HKWorkout)
        
        return cell
    }
    
    @objc func onReload(_ sender: UIRefreshControl) {
        self.populateTable()
    }
    
    @IBAction func onNewSession(_ sender: Any){
        ZBFHealthKit.getPermissions()
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        
        healthStore.startWatchApp(with: configuration) { success, error in
            guard success else {
                print (error.debugDescription)
                return
            }
        }
        
        Mixpanel.mainInstance().time(event: "new_session")
        
        let alert = UIAlertController(title: "Starting Watch App",
                                      message: "Deep Press + Exit when complete.", preferredStyle: .actionSheet)
        
        let ok = UIAlertAction(title: "Done", style: .default) { action in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1) ) {
                Mixpanel.mainInstance().track(event: "new_session")
                self.populateTable()
            }
        }
        
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    //    @IBAction func buddhaClick(_ sender: Any) {
    //        showController("buddha-controller")
    //    }
    //
    //    @IBAction func sanghaClick(_ sender: Any) {
    //        showController("sangha-controller")
    //    }
    //
    //    @IBAction func dharmaClick(_ sender: Any) {
    //        showController("dharma-controller")
    //    }
    //
    //    func showController(_ named: String) {
    //        Mixpanel.mainInstance().time(event: named + "_enter")
    //
    //        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: named)
    //
    //        present(controller, animated: true) {
    //            Mixpanel.mainInstance().track(event: named + "_exit")
    //        }
    //    }
    
    //    @IBAction func actionClick(_ sender: Any) {
    //
    //        #if DEBUG
    //
    //        //self.exportAll() #todo: make this change the attachment when in debug mode
    //
    //        #endif
    //
    //        let vc = UIActivityViewController(activityItems: [url as Any], applicationActivities: [])
    //
    //        vc.excludedActivityTypes = [
    //            UIActivityType.assignToContact,
    //            UIActivityType.saveToCameraRoll,
    //            UIActivityType.postToFlickr,
    //            UIActivityType.postToVimeo,
    //            UIActivityType.postToTencentWeibo,
    //            UIActivityType.postToTwitter,
    //            UIActivityType.postToFacebook,
    //            UIActivityType.openInIBooks
    //        ]
    //
    //        present(vc, animated: true, completion: nil)
    //
    //    }
    //
    //    func exportAll() {
    //
    //        var samples = [[String: Any]]()
    //
    //        let hkPredicate = HKQuery.predicateForObjects(from: HKSource.default())
    //        let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    //
    //        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
    //
    //
    //        let hkQuery = HKSampleQuery.init(sampleType: mindfulSessionType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: {query, results, error in
    //
    //            if error != nil  {
    //                print(error!)
    //            } else {
    //                DispatchQueue.main.sync() {
    //                    samples = results!.map { dictionary in
    //                        var dict: [String: String] = [:]
    //                        dictionary.metadata!.forEach { (key, value) in dict[key] = "\(value)" }
    //                        return dict
    //                    }
    //
    //                    let fileName = "zendo.json"
    //                    let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    //
    //                    let outputStream = OutputStream(url: path!, append: false)
    //
    //                    outputStream?.open()
    //
    //                    JSONSerialization.writeJSONObject(
    //                        samples,
    //                        to: outputStream!,
    //                        options: JSONSerialization.WritingOptions.prettyPrinted,
    //                        error: nil)
    //
    //                    outputStream?.close()
    //
    //                    let vc = UIActivityViewController(activityItems: [path as Any], applicationActivities: [])
    //
    //                    vc.excludedActivityTypes = [
    //                        .assignToContact,
    //                        .saveToCameraRoll,
    //                        .postToFlickr,
    //                        .postToVimeo,
    //                        .postToTencentWeibo,
    //                        .postToTwitter,
    //                        .postToFacebook,
    //                        .openInIBooks
    //                    ]
    //
    //                    self.present(vc, animated: true, completion: nil)
    //
    //                }
    //            }
    //
    //        })
    //
    //        HKHealthStore().execute(hkQuery)
    //
    //    }
    
}
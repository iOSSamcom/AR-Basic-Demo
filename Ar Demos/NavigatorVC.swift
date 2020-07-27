//
//  NavigatorVC.swift
//  Ar Demos
//
//  Created by Parth on 02/07/20.
//  Copyright © 2020 Samcom. All rights reserved.
//

import UIKit

class NavigatorVC: UIViewController {
    
    @IBOutlet weak var tblview: UITableView!
    
    let listArr = ["Adding Text to View","Adding Images from Gallery","Placing Virtual Objects in Augmented Reality","Measure Distance"]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "AR Demos"
        tblview.tableFooterView = UIView()
        // Do any additional setup after loading the view.
    }
    
    
}

extension NavigatorVC:UITableViewDataSource,UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = listArr[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            let vc = AddingTextVC.initViewController()
            vc.title = listArr[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if indexPath.row == 1{
            let vc = AddingImagesController.initViewController()
            vc.title = listArr[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if indexPath.row == 2{
            let vc = PlacingVirtualObjectsVC.initViewController()
            vc.title = listArr[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if indexPath.row == 3{
            let vc = MeasureDistanceVC.initViewController()
            vc.title = listArr[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        }

    }
    
}

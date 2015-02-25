/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Alamofire
import Storage

class TabsPanel: SiteTableViewController {
    private var tabsResponse: TabsResponse?

    override func reloadData() {
        Alamofire.request(.GET, "https://syncapi-dev.sateh.com/1.0/tabs")
            .authenticate(user: "sarentz+syncapi@mozilla.com", password: "q1w2e3r4") // TODO: Get rid of test account and use AccountManager and TabProvider to obtain tabs.
            .responseJSON { (request, response, data, error) in
                self.tabsResponse = parseTabsResponse(data)
                dispatch_async(dispatch_get_main_queue()) {
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let r = tabsResponse {
            return r.clients.count
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let r = tabsResponse {
            return r.clients[section].tabs.count
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)

        if let tab = tabsResponse?.clients[indexPath.section].tabs[indexPath.row] {
            // TODO: We need better async image loading here
            let opts = QueryOptions()
            opts.filter = tab.url
            cell.textLabel?.text = tab.title
        }

        cell.textLabel?.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        cell.textLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
        cell.indentationWidth = 20
        return cell
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = super.tableView(tableView, viewForHeaderInSection: section)

        if let label = view?.viewWithTag(1) as? UILabel {
            if let response = tabsResponse {
                let client = response.clients[section]
                label.text = client.name
            }
        }

        return view
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        if let tab = tabsResponse?.clients[indexPath.section].tabs[indexPath.row] {
            UIApplication.sharedApplication().openURL(NSURL(string: tab.url)!)
        }
    }
}

private class Tab {
    var title: String
    var url: String

    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

private class TabClient {
    var name: String
    var tabs: [Tab] = []

    init(name: String) {
        self.name = name
    }
}

private class TabsResponse: NSObject {
    var clients: [TabClient] = []
}

private func parseTabsResponse(response: AnyObject?) -> TabsResponse {
    let tabsResponse = TabsResponse()

    if let response: NSArray = response as? NSArray {
        for client in response {
            let tabClient = TabClient(name: client.valueForKey("clientName") as String)
            if let tabs = client.valueForKey("tabs") as? NSArray {
                for tab in tabs {
                    var title = ""
                    var url = ""
                    if let t = tab.valueForKey("title") as? String {
                        title = t
                    }
                    if let u = tab.valueForKey("urlHistory") as? NSArray {
                        if u.count > 0 {
                            url = u[0] as String
                        }
                    }
                    tabClient.tabs.append(Tab(title: title, url: url))
                }
            }

            tabsResponse.clients.append(tabClient)
        }
    }

    return tabsResponse
}
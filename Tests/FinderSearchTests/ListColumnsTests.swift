import AppKit
import XCTest
@testable import FinderSearch

final class ListColumnsTests: XCTestCase {
    @MainActor func testMenusTogglePersistAndSyncWithoutChangingSelection() throws {
        let suite = "ListColumnsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = SearchModel()
        model.hits = [Hit(path: "/fixture/example.txt", kind: "file", size: 1, mtime: 0, score: 0)]
        let list = FileList(model: model, focusFiles: {}, newTab: { _ in })
        let coordinator = list.makeCoordinator()
        let scroll = list.makeView(coordinator: coordinator)
        let table = try XCTUnwrap(scroll.documentView as? BrowserTable)
        table.configureColumns(defaults: defaults)
        coordinator.update()
        table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)

        let otherCoordinator = list.makeCoordinator()
        let otherScroll = list.makeView(coordinator: otherCoordinator)
        let otherTable = try XCTUnwrap(otherScroll.documentView as? BrowserTable)
        otherTable.configureColumns(defaults: defaults)
        let headerMenu = try XCTUnwrap(table.headerView?.menu)
        let sizeItem = try XCTUnwrap(headerMenu.items.first { $0.representedObject as? String == "size" })
        let nameItem = try XCTUnwrap(headerMenu.items.first { $0.representedObject as? String == "name" })
        XCTAssertFalse(nameItem.isEnabled)
        XCTAssertEqual(nameItem.state, .on)
        XCTAssertNil(defaults.object(forKey: BrowserTable.columnVisibilityKey))
        for row in [-1, 0] {
            XCTAssertNotNil(coordinator.menu(for: row).items.first { $0.submenu?.items.count == 5 })
        }

        XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(sizeItem.action), to: sizeItem.target, from: sizeItem))
        let identifier = NSUserInterfaceItemIdentifier("size")
        XCTAssertTrue(try XCTUnwrap(table.tableColumn(withIdentifier: identifier)).isHidden)
        XCTAssertTrue(try XCTUnwrap(otherTable.tableColumn(withIdentifier: identifier)).isHidden)
        XCTAssertEqual(table.selectedRowIndexes, IndexSet(integer: 0))
        table.menuNeedsUpdate(headerMenu)
        XCTAssertEqual(sizeItem.state, .off)
        coordinator.update()
        XCTAssertTrue(try XCTUnwrap(table.tableColumn(withIdentifier: identifier)).isHidden)

        let restoredCoordinator = list.makeCoordinator()
        let restoredScroll = list.makeView(coordinator: restoredCoordinator)
        let restoredTable = try XCTUnwrap(restoredScroll.documentView as? BrowserTable)
        restoredTable.configureColumns(defaults: defaults)
        XCTAssertTrue(try XCTUnwrap(restoredTable.tableColumn(withIdentifier: identifier)).isHidden)
        XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(sizeItem.action), to: sizeItem.target, from: sizeItem))
        XCTAssertFalse(try XCTUnwrap(restoredTable.tableColumn(withIdentifier: identifier)).isHidden)
    }

    @MainActor func testLocationDefaultsFollowSearchUntilExplicitlyChosen() throws {
        let suite = "ListColumnsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let list = FileList(model: SearchModel(), focusFiles: {}, newTab: { _ in })
        let coordinator = list.makeCoordinator()
        let scroll = list.makeView(coordinator: coordinator)
        let table = try XCTUnwrap(scroll.documentView as? BrowserTable)
        table.configureColumns(defaults: defaults)
        let location = try XCTUnwrap(table.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("where")))
        XCTAssertTrue(location.isHidden)
        table.isSearch = true
        XCTAssertFalse(location.isHidden)
        let menu = table.columnsMenu()
        let item = try XCTUnwrap(menu.items.first { $0.representedObject as? String == "where" })
        XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(item.action), to: item.target, from: item))
        table.isSearch = false; table.isSearch = true
        XCTAssertTrue(location.isHidden)
        XCTAssertTrue(NSApp.sendAction(try XCTUnwrap(item.action), to: item.target, from: item))
        table.isSearch = false
        XCTAssertFalse(location.isHidden)
    }
}

/*
 * This file is part of Katvan
 * Copyright (c) 2024 - 2026 Igor Khanin
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#import "macshell_exporter.h"

static NSMenu* buildMenuForPopup(NSArray<NSArray<NSString*>*>* items)
{
    NSMenu* menu = [[NSMenu alloc] init];
    for (NSArray<NSString*>* entry in items) {
        if (entry.count != 2) {
            continue;
        }
        NSMenuItem* item = [menu addItemWithTitle:entry[0] action:nil keyEquivalent:@""];
        item.representedObject = entry[1];
    }
    return menu;
}

static void addControlRow(NSGridView* grid, NSView* control, NSString* label)
{
    NSView* labelView = label
        ? [NSTextField labelWithString:label]
        : [[NSView alloc] init];

    [grid addRowWithViews:@[labelView, control]];
}

@interface KatvanPdfExportAccessory : NSViewController

@property (nonatomic) NSPopUpButton* pdfVersionPopup;
@property (nonatomic) NSPopUpButton* pdfaStandardPopup;
@property (nonatomic) NSButton* generateTagsCheckbox;

@end

@implementation KatvanPdfExportAccessory

- (void)loadView
{
    NSMenu* versionsMenu = buildMenuForPopup(@[
        @[@"PDF 1.4", @"1.4"],
        @[@"PDF 1.5", @"1.5"],
        @[@"PDF 1.6", @"1.6"],
        @[@"PDF 1.7", @"1.7"],
        @[@"PDF 2.0", @"2.0"],
    ]);

    self.pdfVersionPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    self.pdfVersionPopup.target = self;
    self.pdfVersionPopup.action = @selector(pdfVersionChanged:);
    self.pdfVersionPopup.menu = versionsMenu;

    [self.pdfVersionPopup selectItemWithTitle:@"PDF 1.7"];

    self.pdfaStandardPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    self.pdfaStandardPopup.target = self;
    self.pdfaStandardPopup.action = @selector(pdfaStandardChanged:);
    [self pdfVersionChanged:nil];

    self.generateTagsCheckbox = [NSButton checkboxWithTitle:NSLocalizedString(@"Generate tagged PDF", "Checkbox in PDF export options")
                                          target:nil
                                          action:nil];
    self.generateTagsCheckbox.state = NSControlStateValueOn;

    NSGridView* grid = [NSGridView gridViewWithNumberOfColumns:2 rows:0];
    grid.translatesAutoresizingMaskIntoConstraints = NO;
    grid.rowSpacing = 12;
    grid.columnSpacing = 10;

    [grid setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationVertical];
    [grid columnAtIndex:0].xPlacement = NSGridCellPlacementTrailing;
    [grid columnAtIndex:1].xPlacement = NSGridCellPlacementFill;

    addControlRow(grid, self.pdfVersionPopup, NSLocalizedString(@"PDF Version:", "Field label in PDF export options"));
    addControlRow(grid, self.pdfaStandardPopup, NSLocalizedString(@"PDF/A Standard:", "Field label in PDF export options"));
    addControlRow(grid, self.generateTagsCheckbox, nil);

    self.view = grid;
}

- (void)pdfVersionChanged:(id)sender
{
    NSString* pdfVersion = self.pdfVersionPopup.selectedItem.representedObject;
    NSString* selectedStandardTitle = self.pdfaStandardPopup.titleOfSelectedItem;
    if (!selectedStandardTitle) {
        selectedStandardTitle = @"";
    }

    NSMutableArray<NSArray<NSString*>*>* standards = [[NSMutableArray alloc] init];
    [standards addObject:@[NSLocalizedString(@"None", nil), @""]];

    // FIXME: This duplicates a lot of static definitions with the Qt shell export
    // dialog. Find a way to unify at least the version/standard matrix.
    if ([pdfVersion isLessThanOrEqualTo:@"1.4"]) {
        [standards addObject:@[@"PDF/A-1b", @"a-1b"]];
        [standards addObject:@[@"PDF/A-1a", @"a-1a"]];
    }
    if ([pdfVersion isLessThanOrEqualTo:@"1.7"]) {
        [standards addObject:@[@"PDF/A-2b", @"a-2b"]];
        [standards addObject:@[@"PDF/A-2u", @"a-2u"]];
        [standards addObject:@[@"PDF/A-2a", @"a-2a"]];
        [standards addObject:@[@"PDF/A-3b", @"a-3b"]];
        [standards addObject:@[@"PDF/A-3u", @"a-3u"]];
        [standards addObject:@[@"PDF/A-3a", @"a-3a"]];
    }
    if ([pdfVersion isEqualToString:@"2.0"]) {
        [standards addObject:@[@"PDF/A-4", @"a-4"]];
        [standards addObject:@[@"PDF/A-4f", @"a-4f"]];
        [standards addObject:@[@"PDF/A-4e", @"a-4e"]];
    }
    if ([pdfVersion isLessThanOrEqualTo:@"1.7"]) {
        [standards addObject:@[@"PDF/UA-1", @"ua-1"]];
    }

    NSMenu* menu = buildMenuForPopup(standards);
    self.pdfaStandardPopup.menu = menu;

    NSMenuItem* preselected = [menu itemWithTitle:selectedStandardTitle];
    if (preselected) {
        [self.pdfaStandardPopup selectItem:preselected];
    }
    else {
        [self.pdfaStandardPopup selectItemAtIndex:0];
    }
}

- (void)pdfaStandardChanged:(id)sender
{
    NSString* standard = self.pdfaStandardPopup.selectedItem.representedObject;
    BOOL taggingRequired = [standard isEqualToString:@"a-1a"]
        || [standard isEqualToString:@"a-2a"]
        || [standard isEqualToString:@"a-3a"]
        || [standard isEqualToString:@"ua-1"];

    if (taggingRequired) {
        self.generateTagsCheckbox.enabled = NO;
        self.generateTagsCheckbox.state = NSControlStateValueOn;
    }
    else {
        self.generateTagsCheckbox.enabled = YES;
    }
}

- (QString)pdfVersion
{
    NSString* version = self.pdfVersionPopup.selectedItem.representedObject;
    return QString::fromNSString(version);
}

- (QString)pdfaStandard
{
    NSString* standard = self.pdfaStandardPopup.selectedItem.representedObject;
    return QString::fromNSString(standard);
}

- (BOOL)generateTaggedPdf
{
    return self.generateTagsCheckbox.state == NSControlStateValueOn;
}

@end

@interface KatvanExporter ()

@property (nonatomic) katvan::TypstDriverWrapper* driver;
@property (nonatomic, weak) NSWindow* window;

@property (nonatomic) NSPDFPanel* pdfPanel;
@property (nonatomic) KatvanPdfExportAccessory* pdfOptions;

@end

@implementation KatvanExporter

- (instancetype)initWithDriver:(katvan::TypstDriverWrapper*)driver andWindow:(NSWindow*)window
{
    self = [super init];
    if (self) {
        self.driver = driver;
        self.window = window;

        self.pdfOptions = [[KatvanPdfExportAccessory alloc] init];

        self.pdfPanel = [NSPDFPanel panel];
        self.pdfPanel.accessoryController = self.pdfOptions;
    }
    return self;
}

- (BOOL)canExport
{
    katvan::TypstDriverWrapper::Status status = self.driver->status();
    return status == katvan::TypstDriverWrapper::Status::SUCCESS
        || status == katvan::TypstDriverWrapper::Status::SUCCESS_WITH_WARNINGS;
}

- (NSString*)fileBaseName
{
    NSString* filename = self.window.representedFilename;
    if ([filename length] > 0) {
        return filename.lastPathComponent.stringByDeletingPathExtension;
    }
    return nil;
}

- (void)exportAsPdf
{
    NSPDFInfo* info = [[NSPDFInfo alloc] init];

    NSString* baseName = [self fileBaseName];
    if (baseName) {
        self.pdfPanel.defaultFileName = baseName; // No .pdf suffix
    }

    [self.pdfPanel beginSheetWithPDFInfo:info
                   modalForWindow:self.window
                   completionHandler:^(NSInteger rc) {
                        if (!rc) {
                            return;
                        }
                        QString path = QString::fromNSString(info.URL.path);
                        QString pdfVersion = [self.pdfOptions pdfVersion];
                        QString pdfaStandard = [self.pdfOptions pdfaStandard];
                        bool tagged = [self.pdfOptions generateTaggedPdf];

                        self.driver->exportToPdf(path, pdfVersion, pdfaStandard, tagged);
                    }];
}

@end

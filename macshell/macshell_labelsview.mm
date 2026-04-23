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
#import "macshell_labelsview.h"

@interface KatvanLabelItem : NSObject

@property (nonatomic, retain) NSString* labelName;
@property (nonatomic, retain) NSImage* icon;
@property (nonatomic) int line;
@property (nonatomic) int column;

- (instancetype)initWithName:(NSString*)name line:(int)line column:(int)column;

@end

@implementation KatvanLabelItem

- (instancetype)initWithName:(NSString*)name line:(int)line column:(int)column
{
    self = [super init];
    if (self) {
        _labelName = name;
        _line = line;
        _column = column;

        if (line >= 0) {
            _icon = [NSImage imageWithSystemSymbolName:@"link" accessibilityDescription:nil];
        }
    }
    return self;
}

@end

@interface KatvanLabelsView ()

@property (nonatomic) NSScrollView* scrollView;
@property (nonatomic) NSTableView* tableView;
@property (nonatomic) NSSearchField* filterField;
@property (nonatomic) NSArrayController* arrayController;

@end

@implementation KatvanLabelsView

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.arrayController = [[NSArrayController alloc] init];
    self.arrayController.objectClass = [KatvanLabelItem class];
    [self.arrayController setSortDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"labelName" ascending:YES selector:@selector(caseInsensitiveCompare:)],
        [NSSortDescriptor sortDescriptorWithKey:@"line" ascending:YES],
        [NSSortDescriptor sortDescriptorWithKey:@"column" ascending:YES]
    ]];

    self.scrollView = [[NSScrollView alloc] init];
    self.scrollView.hasVerticalScroller = YES;
    self.scrollView.hasHorizontalScroller = NO;
    self.scrollView.autohidesScrollers = YES;
    self.scrollView.borderType = NSNoBorder;
    self.scrollView.drawsBackground = NO;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;

    self.tableView = [[NSTableView alloc] init];
    self.tableView.headerView = nil;
    self.tableView.focusRingType = NSFocusRingTypeNone;
    self.tableView.usesAutomaticRowHeights = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.target = self;
    self.tableView.action = @selector(labelSelected:);

    NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:@"labelName"];
    [self.tableView addTableColumn:column];

    [self.tableView bind:NSContentBinding
                    toObject:self.arrayController
                    withKeyPath:@"arrangedObjects"
                    options:nil];
    [self.tableView bind:NSSelectionIndexesBinding
                    toObject:self.arrayController
                    withKeyPath:@"selectionIndexes"
                    options:nil];

    self.scrollView.documentView = self.tableView;

    [self.view addSubview:self.scrollView];

    self.filterField = [[NSSearchField alloc] init];
    self.filterField.translatesAutoresizingMaskIntoConstraints = NO;
    self.filterField.placeholderString = NSLocalizedString(@"Filter", "Placeholder text in labels filter field");
    self.filterField.target = self;
    self.filterField.action = @selector(filterChanged:);

    [self.view addSubview:self.filterField];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.filterField.topAnchor],
        [self.filterField.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [self.filterField.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [self.filterField.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (void)setLabels:(QList<katvan::typstdriver::DocumentLabel>)labels
{
    NSMutableArray<KatvanLabelItem*>* items = [[NSMutableArray alloc] initWithCapacity:labels.size()];
    for (const auto& [name, line, column] : labels) {
        KatvanLabelItem* item = [[KatvanLabelItem alloc] initWithName:name.toNSString() line:line column:column];
        [items addObject:item];
    }

    [self.arrayController setContent:items];
}

- (void)filterChanged:(id)sender
{
    NSString* filterText = self.filterField.stringValue;
    if (filterText.length == 0) {
        [self.arrayController setFilterPredicate:nil];
    }
    else {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"labelName CONTAINS[cd] %@", filterText];
        [self.arrayController setFilterPredicate:predicate];
    }
}

- (void)labelSelected:(id)sender
{
    NSArray<KatvanLabelItem*>* selected = self.arrayController.selectedObjects;
    if (selected.count == 0) {
        return;
    }

    KatvanLabelItem* item = selected.firstObject;
    if (item.line >= 0 && item.column >= 0) {
        [self.target goToBlock:item.line column:item.column];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    // NOTE: This method isn't actually used (the data comes to the table via
    // KVB), but needed to satisfy the NSTableViewDataSource protocol (or else
    // there is a runtime warning). The protocol is only adopted for drag and
    // drop.
    return [self.arrayController.arrangedObjects count];
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
    return [self.arrayController.arrangedObjects objectAtIndex:row];
}

- (id<NSPasteboardWriting>)tableView:(NSTableView*)tableView pasteboardWriterForRow:(NSInteger)row
{
    KatvanLabelItem* item = [self.arrayController.arrangedObjects objectAtIndex:row];
    return [NSString stringWithFormat:@"katvan-label-ref:%@", item.labelName];
}

- (NSView*)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
    NSTableCellView* cellView = [tableView makeViewWithIdentifier:@"labelCell" owner:self];
    if (cellView == nil) {
        cellView = [[NSTableCellView alloc] init];
        cellView.identifier = @"labelCell";

        NSImageView* imageView = [NSImageView imageViewWithImage:[NSImage new]];
        imageView.contentTintColor = NSColor.secondaryLabelColor;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [imageView setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
        [cellView addSubview:imageView];
        cellView.imageView = imageView;

        NSTextField* textField = [NSTextField labelWithString:@""];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [cellView addSubview:textField];
        cellView.textField = textField;

        [NSLayoutConstraint activateConstraints:@[
            [imageView.leadingAnchor constraintEqualToAnchor:cellView.leadingAnchor],
            [imageView.centerYAnchor constraintEqualToAnchor:cellView.centerYAnchor],
            [imageView.widthAnchor constraintEqualToConstant:16],
            [imageView.heightAnchor constraintEqualToConstant:16],
            [textField.leadingAnchor constraintEqualToAnchor:imageView.trailingAnchor constant:4],
            [textField.trailingAnchor constraintEqualToAnchor:cellView.trailingAnchor],
            [textField.centerYAnchor constraintEqualToAnchor:cellView.centerYAnchor]
        ]];

        [cellView.imageView bind:NSValueBinding
                            toObject:cellView
                            withKeyPath:@"objectValue.icon"
                            options:nil];
        [cellView.textField bind:NSValueBinding
                            toObject:cellView
                            withKeyPath:@"objectValue.labelName"
                            options:nil];
    }
    return cellView;
}

@end

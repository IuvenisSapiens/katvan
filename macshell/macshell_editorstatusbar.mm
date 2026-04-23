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
#import "macshell_editorstatusbar.h"

static constexpr CGFloat kStatusBarHeight = 22.0;
static constexpr CGFloat kSectionPadding = 8.0;

@interface KatvanEditorStatusBar ()

@property (nonatomic) NSTextField* cursorPositionLabel;
@property (nonatomic) NSTextField* wordCountLabel;
@property (nonatomic) NSPopUpButton* cursorMoveStylePopup;

@property (nonatomic) NSAttributedString* cursorPositionLabelTemplate;

@end

@implementation KatvanEditorStatusBar

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        self.cursorPositionLabelTemplate = [self makeCursorPositionLabelTemplate];
        self.cursorPositionLabel = [self createLabelSection];

        [self.cursorPositionLabel setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1
                                  forOrientation:NSLayoutConstraintOrientationHorizontal];

        self.wordCountLabel = [self createLabelSection];
        [self updateWordCount:0];

        _cursorMoveStyle = KatvanCursorMoveStyleLogical;

        self.cursorMoveStylePopup = [self createPopUpSection];
        self.cursorMoveStylePopup.toolTip = NSLocalizedString(@"Cursor move style", "Tooltip of status bar item");
        self.cursorMoveStylePopup.target = self;
        self.cursorMoveStylePopup.action = @selector(cursorMoveStylePopupChanged:);
        [self.cursorMoveStylePopup addItemsWithTitles:@[
            NSLocalizedString(@"Logical", "Cursor move style"),
            NSLocalizedString(@"Visual", "Cursor move style")
        ]];

        NSBox* topBorder = [[NSBox alloc] init];
        topBorder.boxType = NSBoxSeparator;
        topBorder.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:topBorder];

        NSStackView* stackView = [NSStackView stackViewWithViews:@[
            self.cursorPositionLabel,
            [self createSeparatorSection],
            self.wordCountLabel,
            [self createSeparatorSection],
            self.cursorMoveStylePopup
        ]];
        stackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        stackView.alignment = NSLayoutAttributeCenterY;
        stackView.distribution = NSStackViewDistributionFill;
        stackView.spacing = kSectionPadding;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:stackView];

        [NSLayoutConstraint activateConstraints:@[
            [self.heightAnchor constraintEqualToConstant:kStatusBarHeight],
            [topBorder.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [topBorder.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [topBorder.topAnchor constraintEqualToAnchor:self.topAnchor],
            [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:kSectionPadding],
            [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-kSectionPadding],
            [stackView.topAnchor constraintEqualToAnchor:topBorder.bottomAnchor],
            [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        ]];
    }
    return self;
}

- (NSBox*)createSeparatorSection
{
    NSBox* separator = [[NSBox alloc] init];
    separator.boxType = NSBoxSeparator;
    separator.translatesAutoresizingMaskIntoConstraints = NO;

    [NSLayoutConstraint activateConstraints:@[
        [separator.widthAnchor constraintEqualToConstant:1.0],
        [separator.heightAnchor constraintEqualToConstant:kStatusBarHeight - 6.0],
    ]];

    return separator;
}

- (NSTextField*)createLabelSection
{
    NSTextField* label = [NSTextField labelWithString:@""];
    label.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    label.textColor = NSColor.secondaryLabelColor;
    label.translatesAutoresizingMaskIntoConstraints = NO;

    return label;
}

- (NSPopUpButton*)createPopUpSection
{
    NSPopUpButton* popUp = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    popUp.bordered = NO;
    popUp.font = [NSFont systemFontOfSize:NSFont.smallSystemFontSize];
    popUp.controlSize = NSControlSizeSmall;
    popUp.translatesAutoresizingMaskIntoConstraints = NO;

    return popUp;
}

- (void)cursorMoveStylePopupChanged:(id)sender
{
    KatvanCursorMoveStyle style = (KatvanCursorMoveStyle)self.cursorMoveStylePopup.indexOfSelectedItem;

    if (_cursorMoveStyle != style) {
        _cursorMoveStyle = style;
        [self.delegate cursorMovementStyleChanged:style];
    }
}

- (void)setCursorMoveStyle:(KatvanCursorMoveStyle)cursorMoveStyle
{
    if (_cursorMoveStyle != cursorMoveStyle) {
        _cursorMoveStyle = cursorMoveStyle;
        [self.cursorMoveStylePopup selectItemAtIndex:(NSInteger)cursorMoveStyle];
        [self.delegate cursorMovementStyleChanged:cursorMoveStyle];
    }
}

- (NSAttributedString*)makeCursorPositionLabelTemplate
{
    NSDictionary* attrs = @{
        NSForegroundColorAttributeName: NSColor.secondaryLabelColor,
        NSFontAttributeName: [NSFont systemFontOfSize:NSFont.smallSystemFontSize]
    };

    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Line %1$@, Column %2$@", "Text cursor position")
                                       attributes:attrs];
}

- (void)updateCursorPosition:(QTextCursor)cursor
{
    int line = cursor.blockNumber() + 1;
    int column = cursor.positionInBlock();

    NSDictionary* attrs = @{
        NSForegroundColorAttributeName: NSColor.labelColor,
        NSFontAttributeName: [NSFont systemFontOfSize:NSFont.smallSystemFontSize]
    };

    NSAttributedString* lineStr = [[NSAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"%d", line]
        attributes:attrs];

    NSAttributedString* columnStr = [[NSAttributedString alloc]
        initWithString:[NSString stringWithFormat:@"%d", column]
        attributes:attrs];

    NSAttributedString* label = [NSAttributedString localizedAttributedStringWithFormat:self.cursorPositionLabelTemplate,
                                                    lineStr,
                                                    columnStr];

    self.cursorPositionLabel.attributedStringValue = label;
}

- (void)updateWordCount:(NSUInteger)count
{
    NSString* labelFormat = NSLocalizedString(@"%lu Word(s)", "Number of words in document");
    NSString* label = [NSString localizedStringWithFormat:labelFormat, count];
    self.wordCountLabel.stringValue = label;
}

@end

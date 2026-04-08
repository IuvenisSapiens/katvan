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
#import "macshell_spellchecker.h"

#import <AppKit/AppKit.h>

KatvanMacSpellChecker::KatvanMacSpellChecker(QObject* parent)
    : katvan::SpellChecker(parent)
    , d_documentTag(0)
{
    d_documentTag = [NSSpellChecker uniqueSpellDocumentTag];
}

KatvanMacSpellChecker::~KatvanMacSpellChecker()
{
    [[NSSpellChecker sharedSpellChecker] closeSpellDocumentWithTag:d_documentTag];
}

QMap<QString, QString> KatvanMacSpellChecker::findDictionaries()
{
    return QMap<QString, QString>();
}

void KatvanMacSpellChecker::setCurrentDictionary(const QString& dictName, const QString& dictPath)
{
    Q_UNUSED(dictName)
    Q_UNUSED(dictPath)
}

katvan::SpellChecker::MisspelledWordRanges KatvanMacSpellChecker::checkSpelling(const QString& text)
{
    SpellChecker::MisspelledWordRanges result;

    NSSpellChecker* checker = [NSSpellChecker sharedSpellChecker];
    NSString* str = text.toNSString();

    NSUInteger start = 0;
    while (start < [str length]) {
        NSRange range = [checker checkSpellingOfString: str
                                 startingAt:start
                                 language:[checker language]
                                 wrap:NO
                                 inSpellDocumentWithTag:d_documentTag
                                 wordCount:NULL];

        if (range.length == 0) {
            break;
        }

        result.append(std::make_pair(range.location, range.length));
        start = NSMaxRange(range);
    }
    return result;
}

void KatvanMacSpellChecker::addToPersonalDictionary(const QString& word)
{
    NSSpellChecker* checker = [NSSpellChecker sharedSpellChecker];
    [checker learnWord:word.toNSString()];
}

void KatvanMacSpellChecker::ignoreWord(NSString* word)
{
    NSSpellChecker* checker = [NSSpellChecker sharedSpellChecker];
    [checker ignoreWord:word inSpellDocumentWithTag:d_documentTag];
}

void KatvanMacSpellChecker::requestSuggestionsImpl(const QString& word, int position)
{
    NSSpellChecker* checker = [NSSpellChecker sharedSpellChecker];
    NSString* str = word.toNSString();

    NSArray<NSString*>* guesses = [checker guessesForWordRange:NSMakeRange(0, [str length])
                                           inString:str
                                           language:[checker language]
                                           inSpellDocumentWithTag:d_documentTag];

    QList<QString> suggestions;
    for (NSString* guess in guesses) {
        suggestions.append(QString::fromNSString(guess));
    }

    suggestionsCalculated(word, position, suggestions);
}

#include "moc_macshell_spellchecker.cpp"

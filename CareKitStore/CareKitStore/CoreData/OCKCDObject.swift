/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import CoreData
import Foundation

@objc(OCKCDObject)
class OCKCDObject: NSManagedObject {
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var deletedAt: Date?
    @NSManaged var remoteID: String?
    @NSManaged var userInfo: [String: String]?
    @NSManaged var groupIdentifier: String?
    @NSManaged var tags: [String]?
    @NSManaged var source: String?
    @NSManaged var asset: String?
    @NSManaged var notes: Set<OCKCDNote>?

    var localDatabaseID: OCKLocalVersionID? {
        guard !objectID.isTemporaryID else { return nil }
        return OCKLocalVersionID(objectID.uriRepresentation().absoluteString)
    }
}

internal extension OCKCDObject {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
        updatedAt = Date()
        notes = Set()
    }

    func copyValues(from other: OCKObjectCompatible) {
        guard let context = managedObjectContext else { fatalError("Managed object context should never be nil!") }
        createdAt = other.createdAt ?? Date()
        updatedAt = other.updatedAt ?? Date()
        deletedAt = other.deletedAt
        groupIdentifier = other.groupIdentifier
        tags = other.tags
        source = other.source
        remoteID = other.externalID
        userInfo = other.userInfo
        asset = other.asset
        notes = {
            guard let otherNotes = other.notes else { return nil }
            return Set(otherNotes.map {
                let note = OCKCDNote(context: context)
                note.author = $0.author
                note.title = $0.title
                note.content = $0.content
                note.copyValues(from: $0)
                return note
            })
        }()
    }
}

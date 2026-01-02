import Foundation

public struct TaskFilter {
    public var status: UserTask.Status?

    public var searchText: String?

    public var limit: Int = 50

    public var offset: Int = 0



    public init(status: UserTask.Status? = nil,

                searchText: String? = nil,

                limit: Int = 50,

                offset: Int = 0) {

        self.status = status

        self.searchText = searchText

        self.limit = limit

        self.offset = offset

    }



    public var hasFilters: Bool {

        return status != nil || !(searchText?.isEmpty ?? true)

    }

}



// MARK: - Task Statistics



public struct TaskStatistics {


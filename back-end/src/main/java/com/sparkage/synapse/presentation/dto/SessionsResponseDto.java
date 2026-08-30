package com.sparkage.synapse.presentation.dto;

import java.util.List;
import java.util.Map;

public class SessionsResponseDto {
    private List<Map<String, Object>> data;
    private PaginationInfo pagination;
    private String timeRange;
    private String kindFilter;

    public SessionsResponseDto() {}

    public SessionsResponseDto(List<Map<String, Object>> data, PaginationInfo pagination,
                              String timeRange, String kindFilter) {
        this.data = data;
        this.pagination = pagination;
        this.timeRange = timeRange;
        this.kindFilter = kindFilter;
    }

    public List<Map<String, Object>> getData() { return data; }
    public void setData(List<Map<String, Object>> data) { this.data = data; }

    public PaginationInfo getPagination() { return pagination; }
    public void setPagination(PaginationInfo pagination) { this.pagination = pagination; }

    public String getTimeRange() { return timeRange; }
    public void setTimeRange(String timeRange) { this.timeRange = timeRange; }

    public String getKindFilter() { return kindFilter; }
    public void setKindFilter(String kindFilter) { this.kindFilter = kindFilter; }

    public static class PaginationInfo {
        private int page;
        private int pageSize;
        private int total;
        private int totalPages;

        public PaginationInfo() {}

        public PaginationInfo(int page, int pageSize, int total, int totalPages) {
            this.page = page;
            this.pageSize = pageSize;
            this.total = total;
            this.totalPages = totalPages;
        }

        public int getPage() { return page; }
        public void setPage(int page) { this.page = page; }

        public int getPageSize() { return pageSize; }
        public void setPageSize(int pageSize) { this.pageSize = pageSize; }

        public int getTotal() { return total; }
        public void setTotal(int total) { this.total = total; }

        public int getTotalPages() { return totalPages; }
        public void setTotalPages(int totalPages) { this.totalPages = totalPages; }
    }
}

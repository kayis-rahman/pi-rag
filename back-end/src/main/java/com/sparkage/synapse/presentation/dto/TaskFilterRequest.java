package com.sparkage.synapse.presentation.dto;

public class TaskFilterRequest {
    private String status;
    private String search;
    private Integer limit = 50;
    private Integer offset = 0;

    public TaskFilterRequest() {}

    public TaskFilterRequest(String status, String search, Integer limit, Integer offset) {
        this.status = status;
        this.search = search;
        this.limit = limit != null ? limit : 50;
        this.offset = offset != null ? offset : 0;
    }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getSearch() { return search; }
    public void setSearch(String search) { this.search = search; }

    public Integer getLimit() { return limit; }
    public void setLimit(Integer limit) { this.limit = limit; }

    public Integer getOffset() { return offset; }
    public void setOffset(Integer offset) { this.offset = offset; }
}
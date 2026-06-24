"use client";

import React, { ReactNode } from "react";
import {
  Table,
  TableHeader,
  TableColumn,
  TableBody,
  TableRow,
  TableCell,
  Spinner,
  Pagination,
} from "@nextui-org/react";

export interface ColumnItem {
  uid: string;
  name: string;
  sortable?: boolean;
}

export interface DataTableProps<T> {
  columns: ColumnItem[];
  data: T[];
  renderCell: (item: T, columnKey: React.Key) => ReactNode;
  isLoading?: boolean;
  emptyContent?: string | ReactNode;
  topContent?: ReactNode;
  page?: number;
  pages?: number;
  onPageChange?: (page: number) => void;
  selectionMode?: "none" | "single" | "multiple";
  selectedKeys?: "all" | Iterable<React.Key>;
  onSelectionChange?: (keys: "all" | Set<React.Key>) => void;
  onRowAction?: (key: React.Key) => void;
  primaryKey?: string;
  disabledKeys?: Iterable<React.Key>;
}

export function DataTable<T extends Record<string, any>>({
  columns,
  data,
  renderCell,
  isLoading = false,
  emptyContent = "Data tidak ditemukan",
  topContent,
  page = 1,
  pages = 1,
  onPageChange,
  selectionMode = "none",
  selectedKeys,
  onSelectionChange,
  onRowAction,
  primaryKey = "id",
  disabledKeys,
}: DataTableProps<T>) {
  const bottomContent = (
    <div className="flex w-full justify-between items-center px-2 py-2">
      <span className="text-small text-default-400">
        Total {data.length} baris di halaman ini
      </span>
      {pages > 1 && onPageChange ? (
        <Pagination
          isCompact
          showControls
          showShadow
          color="primary"
          page={page}
          total={pages}
          onChange={onPageChange}
        />
      ) : (
        pages === 1 && onPageChange ? (
           <Pagination
            isCompact
            showControls
            showShadow
            color="primary"
            page={1}
            total={1}
            onChange={onPageChange}
            isDisabled
          />
        ) : null
      )}
    </div>
  );

  return (
    <Table
      aria-label="Data Table"
      isHeaderSticky
      bottomContent={bottomContent}
      bottomContentPlacement="outside"
      classNames={{
        wrapper: "max-h-[600px]",
        th: "bg-default-100 text-default-800",
        td: "border-b border-default-200",
      }}
      selectionMode={selectionMode}
      selectedKeys={selectedKeys as any}
      onSelectionChange={onSelectionChange as any}
      onRowAction={onRowAction}
      topContent={topContent}
      topContentPlacement="outside"
      disabledKeys={disabledKeys as any}
    >
      <TableHeader columns={columns}>
        {(column) => (
          <TableColumn
            key={column.uid}
            align={column.uid === "actions" ? "center" : "start"}
            allowsSorting={column.sortable}
          >
            {column.name}
          </TableColumn>
        )}
      </TableHeader>
      <TableBody
        emptyContent={emptyContent}
        items={data}
        isLoading={isLoading}
        loadingContent={<Spinner label="Memuat data..." />}
      >
        {(item) => (
          <TableRow key={item[primaryKey as keyof T] as React.Key}>
            {(columnKey) => (
              <TableCell>{renderCell(item, columnKey)}</TableCell>
            )}
          </TableRow>
        )}
      </TableBody>
    </Table>
  );
}

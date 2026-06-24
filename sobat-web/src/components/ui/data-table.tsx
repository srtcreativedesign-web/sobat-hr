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
  onSelectionChange?: (keys: "all" | Set<React.Key>) => void;
  onRowAction?: (key: React.Key) => void;
  primaryKey?: string;
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
  onSelectionChange,
  onRowAction,
  primaryKey = "id",
}: DataTableProps<T>) {
  const bottomContent =
    pages > 0 && onPageChange ? (
      <div className="flex w-full justify-center">
        <Pagination
          isCompact
          showControls
          showShadow
          color="primary"
          page={page}
          total={pages}
          onChange={onPageChange}
        />
      </div>
    ) : null;

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
      onSelectionChange={onSelectionChange as any}
      onRowAction={onRowAction}
      topContent={topContent}
      topContentPlacement="outside"
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

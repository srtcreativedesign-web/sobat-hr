'use client';

import { useState } from 'react';

interface Organization {
    id: number;
    name: string;
    code: string;
    type: string;
    parent_id?: number | null;
    child_organizations?: Organization[];
    _depth?: number;
    line_style?: string; // solid, dashed, dotted
}

interface OrganizationTreeProps {
    organizations: Organization[];
    onEdit: (org: Organization) => void;
    onAddChild: (parentId: number) => void;
    onAddSibling: (parentId: number | null | undefined) => void;
    onDelete: (id: number) => void;
    onSelect: (org: Organization) => void;
    onAddParent: (child: Organization) => void;
}

interface TreeNodeProps {
    node: Organization;
    onEdit: (org: Organization) => void;
    onAddChild: (parentId: number) => void;
    onAddSibling: (parentId: number | null | undefined) => void;
    onDelete: (id: number) => void;
    onSelect: (org: Organization) => void;
    onAddParent: (child: Organization) => void;
}

const TreeNode = ({ node, onEdit, onAddChild, onAddSibling, onDelete, onSelect, onAddParent }: TreeNodeProps) => {
    // ... (rest of TreeNode logic)
    const hasChildren = node.child_organizations && node.child_organizations.length > 0;

    const getTypeBadge = (type: string) => {
        switch (type) {
            case 'headquarters': return 'bg-[#1C3ECA] text-white';
            case 'branch': return 'bg-[#93C5FD] text-white';
            default: return 'bg-gray-100 text-gray-600';
        }
    };

    const lineClass = node.line_style ? `line-${node.line_style}` : '';

    return (
        <li className={lineClass}>
            <div
                className="org-node group relative cursor-pointer"
                onClick={(e) => {
                    e.stopPropagation(); // Prevent drag event interference if needed
                    onSelect(node);
                }}
            >
                <div className="flex flex-col items-center gap-2">
                    {/* ... (node content) */}
                    <span className={`text-[10px] uppercase font-bold px-2 py-0.5 rounded-full ${getTypeBadge(node.type)}`}>
                        {node.type}
                    </span>
                    <h3 className="font-bold text-[#1C3ECA] text-lg">{node.name}</h3>
                    <p className="text-xs text-gray-400 font-mono">{node.code}</p>

                    {/* Action Buttons (Visible on Hover/Focus) */}
                    <div className="flex items-center gap-2 mt-2 pt-2 border-t border-gray-100 opacity-0 group-hover:opacity-100 transition-opacity justify-center" onClick={(e) => e.stopPropagation()}>
                        <button
                            onClick={() => onAddParent(node)}
                            className="p-1.5 text-white bg-[#dca54c] hover:bg-[#c6913d] rounded-full transition-colors"
                            title="Add Parent (Up)"
                        >
                            <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 10l7-7m0 0l7 7m-7-7v18" /></svg>
                        </button>
                        <button
                            onClick={() => onAddChild(node.id)}
                            className="p-1.5 text-white bg-[#60A5FA] hover:bg-[#8fdad2] rounded-full transition-colors"
                            title="Add Child (Down)"
                        >
                            <svg className="w-4 h-4 text-[#1C3ECA]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" /></svg>
                        </button>
                        <button
                            onClick={() => onAddSibling(node.parent_id)}
                            className="p-1.5 text-white bg-[#93C5FD] hover:bg-[#5a7a75] rounded-full transition-colors"
                            title="Add Sibling (Sideways)"
                        >
                            <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 14v6m-3-3h6M6 10h2a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v2a2 2 0 002 2zm10 0h2a2 2 0 002-2V6a2 2 0 00-2-2h-2a2 2 0 00-2 2v2a2 2 0 002 2zM6 20h2a2 2 0 002-2v-2a2 2 0 00-2-2H6a2 2 0 00-2 2v2a2 2 0 002 2z" /></svg>
                        </button>
                        <button
                            onClick={() => onEdit(node)}
                            className="p-1.5 text-gray-500 hover:text-[#1C3ECA] hover:bg-gray-100 rounded-full transition-colors"
                            title="Edit"
                        >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg>
                        </button>
                        <button
                            onClick={() => onDelete(node.id)}
                            className="p-1.5 text-red-300 hover:text-red-500 hover:bg-red-50 rounded-full transition-colors"
                            title="Delete"
                        >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                        </button>
                    </div>
                </div>
            </div>

            {hasChildren && (
                <ul>
                    {node.child_organizations!.map((child) => (
                        <TreeNode
                            key={child.id}
                            node={child}
                            onEdit={onEdit}
                            onAddChild={onAddChild}
                            onAddSibling={onAddSibling}
                            onDelete={onDelete}
                            onSelect={onSelect}
                            onAddParent={onAddParent}
                        />
                    ))}
                </ul>
            )}
        </li>
    );
};

export default function OrganizationTree({ organizations, onEdit, onAddChild, onAddSibling, onDelete, onSelect, onAddParent }: OrganizationTreeProps) {
    // ... (rest of OrganizationTree logic)
    // Zoom & Pan State
    const [scale, setScale] = useState(1);
    const [dragging, setDragging] = useState(false);
    const [position, setPosition] = useState({ x: 0, y: 0 });
    const [startPos, setStartPos] = useState({ x: 0, y: 0 });

    // Zoom Handlers
    const handleZoomIn = () => setScale(prev => Math.min(prev + 0.1, 2));
    const handleZoomOut = () => setScale(prev => Math.max(prev - 0.1, 0.3));
    const handleReset = () => {
        setScale(1);
        setPosition({ x: 0, y: 0 });
    };

    // Pan Handlers
    const handleMouseDown = (e: React.MouseEvent) => {
        setDragging(true);
        setStartPos({ x: e.clientX - position.x, y: e.clientY - position.y });
    };

    const handleMouseMove = (e: React.MouseEvent) => {
        if (!dragging) return;
        setPosition({
            x: e.clientX - startPos.x,
            y: e.clientY - startPos.y
        });
    };

    const handleMouseUp = () => setDragging(false);

    // Build Tree Logic
    const orgMap = new Map();
    organizations.forEach(org => orgMap.set(org.id, { ...org, child_organizations: [] }));

    const rootNodes: any[] = [];
    orgMap.forEach(org => {
        if (org.parent_id) {
            const parent = orgMap.get(org.parent_id);
            if (parent) {
                parent.child_organizations.push(org);
            } else {
                rootNodes.push(org);
            }
        } else {
            rootNodes.push(org);
        }
    });

    if (organizations.length === 0) {
        return (
            <div className="text-center py-12 bg-white rounded-2xl border border-dashed border-gray-300">
                <p className="text-gray-400">No organizations found.</p>
            </div>
        );
    }

    return (
        <div className="relative w-full h-[600px] bg-gray-50 rounded-xl overflow-hidden border border-gray-200">
            {/* Zoom Controls */}
            <div className="absolute bottom-4 right-4 z-50 flex flex-col gap-2 bg-white p-2 rounded-lg shadow-lg border border-gray-100">
                <button
                    onClick={handleZoomIn}
                    className="p-2 hover:bg-gray-100 rounded-lg text-[#1C3ECA] transition-colors"
                    title="Zoom In"
                >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" /></svg>
                </button>
                <button
                    onClick={handleZoomOut}
                    className="p-2 hover:bg-gray-100 rounded-lg text-[#1C3ECA] transition-colors"
                    title="Zoom Out"
                >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 12H4" /></svg>
                </button>
                <button
                    onClick={handleReset}
                    className="p-2 hover:bg-gray-100 rounded-lg text-[#1C3ECA] transition-colors"
                    title="Reset View"
                >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" /></svg>
                </button>
            </div>

            {/* Draggable Area */}
            <div
                className={`w-full h-full cursor-${dragging ? 'grabbing' : 'grab'} flex items-center justify-center`}
                onMouseDown={handleMouseDown}
                onMouseMove={handleMouseMove}
                onMouseUp={handleMouseUp}
                onMouseLeave={handleMouseUp}
            >
                <div
                    className="org-tree transition-transform duration-100 ease-out origin-center"
                    style={{
                        transform: `translate(${position.x}px, ${position.y}px) scale(${scale})`
                    }}
                >
                    <ul>
                        {rootNodes.map(node => (
                            <TreeNode
                                key={node.id}
                                node={node}
                                onEdit={onEdit}
                                onAddChild={onAddChild}
                                onAddSibling={onAddSibling}
                                onDelete={onDelete}
                                onSelect={onSelect}
                                onAddParent={onAddParent}
                            />
                        ))}
                    </ul>
                </div>
            </div>
        </div>
    );
}

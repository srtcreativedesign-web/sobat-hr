'use client';

import { Approval } from "@/types";
import { format } from "date-fns";

interface ApprovalTimelineProps {
    approvals: Approval[];
}

export default function ApprovalTimeline({ approvals }: ApprovalTimelineProps) {
    // Sort by level
    const sortedApprovals = [...approvals].sort((a, b) => a.level - b.level);

    return (
        <div className="flow-root">
            <h3 className="text-lg font-bold text-[#1C3ECA] mb-4">Approval Timeline</h3>
            <ul role="list" className="-mb-8">
                {sortedApprovals.map((approval, eventIdx) => {
                    const isLast = eventIdx === sortedApprovals.length - 1;

                    let statusColor = "bg-gray-200";
                    let icon = (
                        <span className="h-2.5 w-2.5 rounded-full bg-transparent group-hover:bg-gray-300" />
                    );

                    if (approval.status === 'approved') {
                        statusColor = "bg-green-500";
                        icon = (
                            <svg className="h-5 w-5 text-white" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                                <path fillRule="evenodd" d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z" clipRule="evenodd" />
                            </svg>
                        );
                    } else if (approval.status === 'rejected') {
                        statusColor = "bg-red-500";
                        icon = (
                            <svg className="h-5 w-5 text-white" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                                <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                            </svg>
                        );
                    } else if (approval.status === 'pending') {
                        statusColor = "bg-yellow-400";
                        icon = (
                            <span className="h-2.5 w-2.5 rounded-full bg-white ring-2 ring-white" /> // Simple dot
                        );
                    }

                    const displayNote = approval.note || approval.notes || '';
                    let approverName = (approval.approver?.full_name || 'Approver').replace(/\b\w/g, (l) => l.toUpperCase());
                    let noteToDisplay = displayNote;

                    const match = displayNote.match(/Approved by[:\s]+(.*)/i);
                    if (match) {
                        const extractedName = match[1].trim();
                        // Only override title if it's a real name (not generic 'system/user')
                        if (extractedName.toLowerCase() !== 'system/user') {
                            approverName = extractedName;
                        }
                        // Clean up the note from the display
                        noteToDisplay = displayNote.replace(/Approved by[:\s]+.*/i, '').trim();
                    }

                    // Extra guard to hide generic system note entirely
                    if (noteToDisplay.toLowerCase() === 'approved by system/user') {
                        noteToDisplay = '';
                    }

                    return (
                        <li key={approval.id}>
                            <div className="relative pb-8">
                                {!isLast ? (
                                    <span
                                        className="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200"
                                        aria-hidden="true"
                                    />
                                ) : null}
                                <div className="relative flex space-x-3">
                                    <div className={`flex h-8 w-8 items-center justify-center rounded-full ${statusColor} ring-8 ring-white`}>
                                        {icon}
                                    </div>
                                    <div className="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                                        <div className="flex-1">
                                            <p className="text-sm font-bold text-gray-900 leading-tight">
                                                Level {approval.level}: <span>{approverName}</span>
                                            </p>
                                            {noteToDisplay && (
                                                <p className="text-sm text-gray-500 mt-1 leading-snug">
                                                    {noteToDisplay}
                                                </p>
                                            )}
                                        </div>
                                        <div className="whitespace-nowrap text-right text-xs text-gray-500 tabular-nums">
                                            {approval.acted_at || approval.approved_at ? (
                                                <time dateTime={approval.acted_at || approval.approved_at}>
                                                    {format(new Date(approval.acted_at || approval.approved_at!), 'dd MMM yyyy HH:mm')}
                                                </time>
                                            ) : (
                                                <span className="italic opacity-60">Waiting...</span>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </li>
                    );
                })}
            </ul>
        </div>
    );
}

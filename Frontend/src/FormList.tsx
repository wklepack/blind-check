import { useState } from "react";

interface Props {
    onView: () => void;
}

function fuzzyMatch(query: string, target: string) {
    const q = query.trim().toLowerCase();
    const t = target.toLowerCase();
    if (!q) return true;
    if (t.includes(q)) return true;

    let i = 0;
    for (let j = 0; j < t.length && i < q.length; j++) {
        if (t[j] === q[i]) i++;
    }
    return i === q.length;
}

export default function FormList({ onView }: Props) {
    const [search, setSearch] = useState("");

    const data = [
        { formId: "F12345", verified: true, decedentName: "John Doe" },
        { formId: "F67890", verified: false, decedentName: "Jane Smith" },
        { formId: "F54321", verified: true, decedentName: "Michael Brown" },
        { formId: "F98765", verified: false, decedentName: "Emily Davis" },
        { formId: "F00123", verified: true, decedentName: "Alicia Gomez" },
        { formId: "F00999", verified: false, decedentName: "Robert Chen" },
    ];

    const filtered = data.filter(
        (item) => fuzzyMatch(search, item.formId) || fuzzyMatch(search, item.decedentName)
    );

    function handleViewClick(item: { formId: string; decedentName: string }) {
        onView();
        alert(`Viewing form ${item.formId} — ${item.decedentName}`);
    }

    return (
        <div className="bg-white p-6 rounded-lg shadow-md w-[28rem]">
            <h2 className="text-2xl font-bold mb-4 text-center">Forms</h2>

            {/* Search Field */}
            <input
                type="text"
                placeholder="Search by Form ID or Name"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full mb-4 p-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-teal-400"
            />

            {/* Column Headers */}
            <div className="grid grid-cols-[6rem_1fr_6rem_auto] font-semibold text-gray-700 text-sm border-b pb-2 mb-2">
                <span>Form ID</span>
                <span>Decedent Name</span>
                <span className="text-center">Status</span>
                <span className="text-center">Action</span>
            </div>

            {/* Scrollable List */}
            <div className="max-h-64 overflow-y-auto border border-gray-200 rounded">
                {filtered.map((item) => (
                    <div
                        key={item.formId}
                        className="grid grid-cols-[6rem_1fr_6rem_auto] items-center gap-3 p-3 border-b last:border-none hover:bg-gray-50"
                    >
                        {/* Form ID */}
                        <span className="font-medium">{item.formId}</span>

                        {/* Decedent Name */}
                        <span className="truncate">{item.decedentName}</span>

                        {/* Status Badge */}
                        <span
                            className={`text-xs px-2 py-1 rounded text-center ${
                                item.verified
                                    ? "bg-green-100 text-green-700"
                                    : "bg-red-100 text-red-700"
                            }`}
                        >
                            {item.verified ? "Verified" : "Unverified"}
                        </span>

                        {/* View Icon */}
                        <button
                            type="button"
                            onClick={() => handleViewClick(item)}
                            className="text-gray-500 hover:text-gray-700 p-1 rounded focus:outline-none focus:ring-2 focus:ring-teal-400"
                            title="View"
                        >
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                className="h-5 w-5"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                strokeWidth="2"
                            >
                                <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z" />
                                <circle cx="12" cy="12" r="3" />
                            </svg>
                        </button>
                    </div>
                ))}

                {filtered.length === 0 && (
                    <div className="p-3 text-gray-500 text-center">No results found</div>
                )}
            </div>
        </div>
    );
}

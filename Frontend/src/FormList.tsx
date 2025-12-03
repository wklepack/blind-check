import { useState } from "react";
import { type BlindCheckForm } from "./api";

interface Props {
    onView: (item: BlindCheckForm) => void; // Pass full object for View step
    list: BlindCheckForm[];
    error: string | null;
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

export default function FormList({ onView, list: data, error }: Props) {
    const [search, setSearch] = useState("");
    const filtered = (data ?? []).filter(
        (item) => fuzzyMatch(search, item.contractNumber) || fuzzyMatch(search, item.decedent.name)
    );

    return (
        <div className="bg-white p-6 rounded-lg shadow-md w-[32rem] mx-auto">
            <h2 className="text-2xl font-bold mb-4 text-center">Blind Check Forms</h2>

            {/* Search Field */}
            <input
                type="text"
                placeholder="Search by contract number or decedent name"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full mb-4 p-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-teal-400"
            />

            {/* Column Headers */}
            <div className="flex font-semibold text-gray-700 text-sm border-b pb-2 mb-2">
                <span className="w-32">Contract Number</span>
                <span className="flex-1">Decedent Name</span>
                <span className="w-28 text-center">Status</span>
            </div>

            {/* Scrollable List */}
            <div className="max-h-100 overflow-y-auto border border-gray-200 rounded">
                {!data && !error && <div className="p-3 text-gray-500 text-center">Loading...</div>}
                {error && <div className="p-3 text-red-600 text-center">{error}</div>}
                {data && filtered.length === 0 && (
                    <div className="p-3 text-gray-500 text-center">No results found</div>
                )}

                {filtered.map((item) => (
                    <div
                        key={item.contractNumber}
                        className="flex items-center gap-3 p-3 border-b last:border-none hover:bg-gray-50"
                    >
                        {/* Contract Number */}
                        <span className="w-32 font-medium">{item.contractNumber}</span>

                        {/* Decedent Name */}
                        <span className="flex-1 truncate">{item.decedent.name}</span>

                        {/* Status Badge */}
                        <span
                            className={`w-28 text-xs px-2 py-1 rounded text-center ${
                                item.blindCheckVerification.isVerified
                                    ? "bg-green-100 text-green-700"
                                    : "bg-yellow-100 text-yellow-700"
                            }`}
                        >
                            {item.blindCheckVerification.isVerified ? "Verified" : "Unverified"}
                        </span>

                        {/* View Icon */}
                        <button
                            type="button"
                            onClick={() => onView(item)}
                            className="ml-2 text-gray-500 hover:text-gray-700 p-1 rounded focus:outline-none focus:ring-2 focus:ring-teal-400"
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
            </div>
        </div>
    );
}

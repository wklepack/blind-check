import type { BlindCheckForm } from "./api";

type ViewFormProps = {
    selectedForm: BlindCheckForm;
    onBack: () => void;
};

export default function ViewForm({ selectedForm, onBack }: ViewFormProps) {
    const { contractNumber, counselor, markerPlacements, blindCheckVerification } = selectedForm;
    const isVerified = blindCheckVerification.isVerified;

    const decedentName =
        markerPlacements.length > 0
            ? markerPlacements[0].inscription.split("-")[0].trim()
            : "Unknown";

    return (
        <div className="bg-white p-6 rounded-lg shadow-md w-[32rem] mx-auto">
            {/* Top bar */}
            <div className="flex items-center mb-6">
                <button
                    type="button"
                    onClick={onBack}
                    className="flex items-center gap-2 text-gray-700 hover:text-gray-900 px-2 py-1 rounded focus:outline-none focus:ring-2 focus:ring-teal-400"
                >
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        className="h-5 w-5"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                    >
                        <path d="M15 18l-6-6 6-6" />
                    </svg>
                    <span className="text-sm font-medium">Back</span>
                </button>

                <div className="ml-auto flex items-center gap-3">
                    <h2 className="text-xl font-bold">{contractNumber}</h2>
                    <span
                        className={`text-xs px-2 py-1 rounded ${
                            isVerified
                                ? "bg-green-100 text-green-700"
                                : "bg-yellow-100 text-yellow-700"
                        }`}
                    >
                        {isVerified ? "Verified" : "Unverified"}
                    </span>
                </div>
            </div>

            {/* Arrangement Counselor */}
            <div className="mb-6">
                <h3 className="text-lg font-semibold mb-4">Arrangement Counselor</h3>
                <div className="grid grid-cols-2 gap-4">
                    <LabeledReadonly label="Counselor Name" value={counselor.name} />
                    <LabeledReadonly label="Decedent Name" value={decedentName} />
                </div>
            </div>

            {/* Blind Check */}
            <div className="mb-6">
                <h3 className="text-lg font-semibold mb-4">Blind Check</h3>
                <div className="grid grid-cols-3 gap-4">
                    {Array.from({ length: 9 }).map((_, index) => {
                        const isMiddle = index === 4;
                        const marker = markerPlacements[index] || null;

                        return (
                            <div
                                key={index}
                                className={`flex flex-col items-center justify-center border rounded h-20 text-center ${
                                    isMiddle
                                        ? isVerified
                                            ? "bg-green-100 border-green-400"
                                            : "bg-yellow-100 border-yellow-400"
                                        : "bg-gray-50 border-gray-300"
                                }`}
                            >
                                {isMiddle ? (
                                    <span className="text-sm font-semibold">{decedentName}</span>
                                ) : marker ? (
                                    <span className="text-xs font-medium">
                                        {marker.inscription}
                                    </span>
                                ) : (
                                    <span className="text-xs text-gray-500">—</span>
                                )}
                            </div>
                        );
                    })}
                </div>
            </div>

            {/* ✅ Full-width Print Button */}
            <button
                type="button"
                onClick={() => window.print()}
                className="w-full bg-teal-500 text-white font-semibold py-3 rounded hover:bg-teal-600 focus:outline-none focus:ring-2 focus:ring-teal-400"
            >
                Print Form
            </button>
        </div>
    );
}

/** Helper for labeled read-only fields */
function LabeledReadonly({ label, value }: { label: string; value: string }) {
    return (
        <div>
            <label className="block text-gray-600 text-sm mb-1">{label}</label>
            <input
                type="text"
                value={value}
                readOnly
                className="w-full p-2 border border-gray-300 rounded bg-gray-100"
            />
        </div>
    );
}

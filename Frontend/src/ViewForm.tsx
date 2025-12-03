type Marker = {
    firstName: string;
    lastName: string;
};

type ArrangementData = {
    counselorName: string;
    decedentName: string;
    section: string;
    block: string;
    lot: string;
    building: string;
};

type ViewFormProps = {
    formId: string;
    arrangementData: ArrangementData;
    markers: (Marker | null)[];
    onBack: () => void;
};

export type ViewData = {
    formId: string;
    arrangementData: ArrangementData;
    markers: (Marker | null)[];
};

const mockViewData: ViewData = {
    formId: "F2025-001",
    arrangementData: {
        counselorName: "Kamil Lach",
        decedentName: "Wiktor Filip",
        section: "Cedar",
        block: "B",
        lot: "27",
        building: "Main Chapel",
    },
    // 3x3 grid, index 4 is the middle slot (marked "To Find" in the component)
    markers: [
        { firstName: "Alicia", lastName: "Gomez" }, // 0,0
        { firstName: "Robert", lastName: "Chen" }, // 0,1
        { firstName: "Emily", lastName: "Davis" }, // 0,2
        { firstName: "Michael", lastName: "Brown" }, // 1,0
        null, // 1,1 (middle, "To Find")
        { firstName: "Jane", lastName: "Smith" }, // 1,2
        { firstName: "Noah", lastName: "Johnson" }, // 2,0
        { firstName: "Olivia", lastName: "Martinez" }, // 2,1
        { firstName: "Sophia", lastName: "Lee" }, // 2,2
    ],
};

export default function ViewForm({
    formId = mockViewData.formId,
    arrangementData = mockViewData.arrangementData,
    markers = mockViewData.markers,
    onBack,
}: ViewFormProps) {
    return (
        <div className="bg-white p-6 rounded-lg shadow-md w-[32rem]">
            {/* Top bar with Back button and Form ID */}
            <div className="flex items-center mb-6">
                <button
                    type="button"
                    onClick={onBack}
                    className="flex items-center gap-2 text-gray-700 hover:text-gray-900 px-2 py-1 rounded focus:outline-none focus:ring-2 focus:ring-teal-400"
                    aria-label="Go back"
                    title="Back"
                >
                    {/* Left chevron icon */}
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

                <h2 className="ml-auto text-xl font-bold">Form ID: {formId}</h2>
            </div>

            {/* Arrangement Counselor Section */}
            <div className="mb-6">
                <h3 className="text-lg font-semibold mb-4">Arrangement Counselor</h3>
                <div className="grid grid-cols-2 gap-4">
                    <LabeledReadonly label="Counselor Name" value={arrangementData.counselorName} />
                    <LabeledReadonly label="Decedent Name" value={arrangementData.decedentName} />
                    <LabeledReadonly label="Section" value={arrangementData.section} />
                    <LabeledReadonly label="Block" value={arrangementData.block} />
                    <LabeledReadonly label="Lot" value={arrangementData.lot} />
                    <LabeledReadonly label="Building" value={arrangementData.building} />
                </div>
            </div>

            {/* Blind Check Section */}
            <div>
                <h3 className="text-lg font-semibold mb-4">Blind Check</h3>
                <div className="grid grid-cols-3 gap-4">
                    {markers.map((marker, index) => {
                        const isMiddle = index === 4; // middle of 3x3 grid
                        return (
                            <div
                                key={index}
                                className={`flex flex-col items-center justify-center border rounded h-20 text-center ${
                                    isMiddle
                                        ? "bg-yellow-100 border-yellow-400"
                                        : "bg-gray-50 border-gray-300"
                                }`}
                            >
                                {isMiddle ? (
                                    <span className="text-xs font-bold text-yellow-800">
                                        To Find
                                    </span>
                                ) : marker ? (
                                    <>
                                        <span className="text-sm font-medium">
                                            {marker.firstName}
                                        </span>
                                        <span className="text-sm">{marker.lastName}</span>
                                    </>
                                ) : (
                                    <span className="text-xs text-gray-500">—</span>
                                )}
                            </div>
                        );
                    })}
                </div>
            </div>
        </div>
    );
}

/** Small helper for consistent labeled read-only inputs */
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

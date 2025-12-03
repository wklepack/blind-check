export interface MarkerPlacement {
    x: number; // X coordinate of marker
    y: number; // Y coordinate of marker
    inscription: string; // Text on the marker
}

export interface Counselor {
    name: string; // Counselor's name
}

export interface Decedent {
    name: string;
}

export interface BlindCheckVerification {
    isVerified: boolean; // Whether blind check is verified
    verifiedBy: boolean; // Indicates if verified by a person/system
    verifiedAt: string; // ISO timestamp of verification
}

export interface BlindCheckForm {
    contractNumber: string; // Unique contract number
    counselor: Counselor; // Counselor details
    decedent: Decedent;
    markerPlacements: MarkerPlacement[]; // List of marker placements
    blindCheckVerification: BlindCheckVerification; // Verification details
}

// ✅ Exported functions
export const getListData = async () => {
    const res = await fetch(
        "https://sci-blind-check-poc-aaf7cnedhuffhdbz.polandcentral-01.azurewebsites.net/api/blind-check-form"
    );
    return (await res.json()) as BlindCheckForm[];
};

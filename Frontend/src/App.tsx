import { useState } from "react";
import FormList from "./FormList";
import LoginForm from "./LoginForm";
import Wrapper from "./Wrapper";
import ViewForm from "./ViewForm";
import { getListData, type BlindCheckForm } from "./api";

type FormStep = "Login" | "Search" | "View";

export default function App() {
    const [formStep, setFormStep] = useState<FormStep>("Login");
    const [selectedForm, setSelectedForm] = useState<BlindCheckForm | null>(null);
    const [data, setData] = useState<BlindCheckForm[] | null>(null);
    const [error, setError] = useState<string | null>(null);

    const handleDataFetch = () => {
        const fetchData = async () => {
            try {
                const result = await getListData();
                setData(result ?? []);
            } catch (err) {
                setError("Failed to load forms. Please try again.");
            }
        };
        fetchData();
    };

    return (
        <Wrapper>
            {formStep === "Login" && (
                <LoginForm onLoginStart={handleDataFetch} onLogin={() => setFormStep("Search")} />
            )}
            {formStep === "Search" && data && (
                <FormList
                    error={error}
                    list={data}
                    onView={(form) => {
                        setFormStep("View");
                        setSelectedForm(form);
                    }}
                />
            )}
            {formStep === "View" && selectedForm && (
                <ViewForm selectedForm={selectedForm} onBack={() => setFormStep("Search")} />
            )}
        </Wrapper>
    );
}

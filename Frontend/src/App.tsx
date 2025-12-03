import { useState } from "react";
import FormList from "./FormList";
import LoginForm from "./LoginForm";
import Wrapper from "./Wrapper";
import ViewForm from "./ViewForm";
import type { BlindCheckForm } from "./api";

type FormStep = "Login" | "Search" | "View";

export default function App() {
    const [formStep, setFormStep] = useState<FormStep>("Login");
    const [selectedForm, setSelectedForm] = useState<BlindCheckForm | null>(null);

    return (
        <Wrapper>
            {formStep === "Login" && <LoginForm onLogin={() => setFormStep("Search")} />}
            {formStep === "Search" && (
                <FormList
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

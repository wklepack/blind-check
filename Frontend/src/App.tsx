import { useState } from "react";
import FormList from "./FormList";
import LoginForm from "./LoginForm";
import Wrapper from "./Wrapper";
import ViewForm from "./ViewForm";

type FormStep = "Login" | "Search" | "View";

export default function App() {
    const [formStep, setFormStep] = useState<FormStep>("Login");

    return (
        <Wrapper>
            {formStep === "Login" && <LoginForm onLogin={() => setFormStep("Search")} />}
            {formStep === "Search" && <FormList onView={() => setFormStep("View")} />}
            {formStep === "View" && <ViewForm onBack={() => setFormStep("Search")} />}
        </Wrapper>
    );
}

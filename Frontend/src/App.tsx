import { useState } from "react";
import FormList from "./FormList";
import LoginForm from "./LoginForm";
import Wrapper from "./Wrapper";
import ViewForm from "./ViewForm";

// here  we display grid of cemetery markers with some provided data, each grid box has first name and last name of decedent, the middle grid is empty, mark it as the one to be found on the cemetery by a field person

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

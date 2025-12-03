import { useState } from "react";
import FormList from "./FormList";
import LoginForm from "./LoginForm";
import Wrapper from "./Wrapper";

//arrangement counselor section
// arrangement counselor name
// decedent name
// section
// block
// lot
// building
// tier/level

//administration section
//name

//blind check section
// grid 3x3

type FormStep = "Login" | "Search" | "View";

export default function App() {
    const [formStep, setFormStep] = useState<FormStep>("Login");

    return (
        <Wrapper>
            {formStep === "Login" && <LoginForm onLogin={() => setFormStep("Search")} />}

            {formStep === "Search" && <FormList />}
        </Wrapper>
    );
}

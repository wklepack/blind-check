import { useState } from "react";

interface Props {
    onLogin: () => void;
    onLoginStart: () => void;
}

export default function LoginForm({ onLogin, onLoginStart }: Props) {
    const [loading, setLoading] = useState(false);

    const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        setLoading(true);
        onLoginStart();

        // Fake loading for 2 seconds
        setTimeout(() => {
            setLoading(false);
            console.log("success");

            onLogin();
        }, 2000);
    };

    return (
        <form onSubmit={handleSubmit} className="bg-white p-6 rounded-lg shadow-md w-80 mx-auto">
            <h2 className="text-2xl font-bold mb-4 text-center">Login to you account</h2>

            <div className="mb-4">
                <label htmlFor="login" className="block mb-1 font-medium text-gray-700">
                    Login
                </label>
                <input
                    id="login"
                    type="text"
                    name="login"
                    placeholder="Enter your login"
                    className="w-full p-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-teal-400"
                />
            </div>

            <div className="mb-4">
                <label htmlFor="password" className="block mb-1 font-medium text-gray-700">
                    Password
                </label>
                <input
                    id="password"
                    type="password"
                    name="password"
                    placeholder="Enter your password"
                    className="w-full p-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-teal-400"
                />
            </div>

            <button
                type="submit"
                disabled={loading}
                className={`w-full py-2 rounded text-white font-semibold transition ${
                    loading ? "opacity-70 cursor-not-allowed" : ""
                }`}
                style={{ backgroundColor: "rgb(71, 213, 205)" }}
            >
                {loading ? "Loading..." : "Login"}
            </button>
        </form>
    );
}

type AppWrapperProps = {
    children: React.ReactNode;
};

export default function Wrapper({ children }: AppWrapperProps) {
    return (
        <div className="flex items-center justify-center min-h-screen bg-gray-100">{children}</div>
    );
}

type AppWrapperProps = {
    children: React.ReactNode;
};

export default function Wrapper({ children }: AppWrapperProps) {
    return <div className="min-h-screen bg-gray-100 py-[100px]">{children}</div>;
}

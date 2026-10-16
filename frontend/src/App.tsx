import { BrowserRouter, Navigate, Route, Routes } from "react-router";
import { AuthProvider } from "./auth/AuthProvider";
import LoginPage from "./pages/LoginPage";
import RegisterPage from "./pages/RegisterPage";
import StorePage from "./pages/StorePage";
import StoresPage from "./pages/StoresPage";
import ProductsPage from "./pages/ProductsPage";
import InventoryPage from "./pages/InventoryPage";
import OrdersPage, { OrderDetailPage } from "./pages/OrdersPage";
import ReportsPage from "./pages/ReportsPage";
import StorefrontPage, { CartPage, CheckoutPage, ConfirmationPage, StorefrontProductPage } from "./pages/StorefrontPage";
import CustomersPage, { CustomerDetailPage } from "./pages/CustomersPage";
import SkipLink from "./pages/SkipLink";

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <SkipLink />
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/stores" element={<StoresPage />} />
          <Route path="/stores/:storeId" element={<StorePage />} />
          <Route path="/stores/:storeId/products" element={<ProductsPage />} />
          <Route path="/stores/:storeId/inventory" element={<InventoryPage />} />
          <Route path="/stores/:storeId/orders" element={<OrdersPage />} />
          <Route path="/stores/:storeId/orders/:orderId" element={<OrderDetailPage />} />
          <Route path="/stores/:storeId/customers" element={<CustomersPage />} />
          <Route path="/stores/:storeId/customers/:customerId" element={<CustomerDetailPage />} />
          <Route path="/stores/:storeId/reports" element={<ReportsPage />} />
          <Route path="/s/:handle" element={<StorefrontPage />} />
          <Route path="/s/:handle/products/:productHandle" element={<StorefrontProductPage />} />
          <Route path="/s/:handle/cart" element={<CartPage />} />
          <Route path="/s/:handle/checkout" element={<CheckoutPage />} />
          <Route path="/s/:handle/orders/:number" element={<ConfirmationPage />} />
          <Route path="*" element={<Navigate to="/stores" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

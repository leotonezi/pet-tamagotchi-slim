import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import ProtectedRoute from './components/shared/ProtectedRoute'
import { AuthProvider } from './contexts/AuthContext'
import PetDetailPage from './pages/PetDetailPage'
import PetListPage from './pages/PetListPage'
import ShopPage from './pages/ShopPage'
import RewardsPage from './pages/RewardsPage'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route
            path="/pets"
            element={<ProtectedRoute><PetListPage /></ProtectedRoute>}
          />
          <Route
            path="/pets/:id"
            element={<ProtectedRoute><PetDetailPage /></ProtectedRoute>}
          />
          <Route
            path="/shop"
            element={<ProtectedRoute><ShopPage /></ProtectedRoute>}
          />
          <Route
            path="/rewards"
            element={<ProtectedRoute><RewardsPage /></ProtectedRoute>}
          />
          <Route path="*" element={<Navigate to="/pets" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}

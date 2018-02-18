module Minilang.Eval where

import           Data.Text       (Text)
import           Minilang.Parser

type Name = Text

data Env = EmptyEnv
         | ExtendPat Env Binding Value
  deriving (Eq, Show)

emptyEnv :: Env
emptyEnv = EmptyEnv

data Value = EI Integer | ED Double
           | EU | EUnit
           | EPair Value Value
           | EAbs FunClos
           | EPi Value FunClos
           | ESig Value FunClos
  deriving (Eq, Show)

data FunClos = Cl Binding AST Env
  deriving (Eq, Show)

eval
  :: AST -> Env -> Value
eval (I n)      _ = EI n
eval (D d)      _ = ED d
eval U          _ = EU
eval Unit       _ = EUnit
eval (Pair a b)  ρ = EPair (eval a ρ) (eval b ρ)
eval (Abs p e)  ρ  = EAbs $ Cl p e ρ
eval (Pi p t e) ρ  = EPi (eval t ρ) $ Cl p e ρ
eval (Sigma p t e) ρ = ESig (eval t ρ) $ Cl p e ρ
eval (Ap u v)      ρ = app (eval u ρ) (eval v ρ)
eval (Var x) ρ = rho ρ x
eval e ρ       = error $ "don't know how to evaluate " ++ show e ++ " in  " ++ show ρ


app :: Value -> Value -> Value
app (EAbs f@Cl{}) v = inst f v
app _ _             = undefined

inst :: FunClos -> Value -> Value
inst (Cl b e ρ) v = eval e (ExtendPat ρ b v)

rho :: Env -> Name -> Value
rho EmptyEnv x = error $ "name " ++ show x ++ " is not defined in empty environment"
rho (ExtendPat ρ b v) x
  | x `inPat` b = proj x b v
  | otherwise   = rho ρ x

inPat :: Name -> Binding -> Bool
inPat x (B p') | x == p' = True
inPat _ _      = undefined

proj :: Name -> Binding -> Value -> Value
proj _ (B _) v = v
proj _ _ _     = undefined

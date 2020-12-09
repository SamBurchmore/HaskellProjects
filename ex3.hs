{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}
module Ex3 where

{----------------------------------------------------------------------}
{- CS316 (2020/2021) EXERCISE 3                                       -}
{----------------------------------------------------------------------}

{- Please read this file carefully.
   The exercise is split into 3 parts:
   - Part 1 (25 marks) is concerned with CSV Files
   - Part 2 (25 marks) is concerned with a small Expression language
   - Part 3 (30 marks) is an open ended project for you to do that
     combines the previous two parts.
   The questions this time are chunkier that the ones in Exercises 1
   and 2, and often have opportunties to have an easy solution for
   some marks, and a more featureful solution for all the marks.
   Submission instructions:
    - Deadline: 23:00 Thursday 3rd December
    - Location: CS316 MyPlace
   This exercise is worth 40% of your overall mark for CS316. It is
   marked out of 80, so one mark here is worth half a percentage
   point.
   Note about plagiarism: You can discuss the questions with others to
   make sure that you understand the questions. However, you must
   write up your answers by yourself. Do not share your solutions
   online (e.g., on GitHub or other code sharing platforms. Use a
   private repository if you want have a backup).
   Plagiarism will be taken very seriously. -}

{------------------------------------------------------------------------}
{- Part 0 : Some helpful functions (0 marks)                            -}
{------------------------------------------------------------------------}

{- For this exercise, you will likely need some useful functions. Here
   are the module imports for them. -}

import           Data.List (intersperse, isPrefixOf)

{- 'intersperse' is a function that puts something between every element
   of a list:
     > intersperse "and" ["one","two","three"]
     ["one","and","two","and","three"]
     > intersperse " " (intersperse "and" ["one","two","three"])
     ["one"," ","and"," ","two"," ","and"," ","three"]
     > concat (intersperse " " (intersperse "and" ["one","two","three"]))
     "one and two and three"
   'isPrefixOf' returns 'True' if its first argument is a prefix of
   its second, and 'False' otherwise:
     > isPrefixOf "Ben" "Ben Nevis"
     True
     > isPrefixOf "Ben" "Cairn Gorm"
     False
-}

import           Control.Monad (filterM)
{- 'filterM :: Monad m => (a -> m Bool) -> [a] -> m [b]' is a function
   that is like 'filter' but the filtering function may perform some
   side effect. It is similar to how 'mapM' (week 7) is the monad
   version of 'map' (week 3). -}


{- The 'Result' module implements a 'Result' monad as in the Week 07
   tutorial questions: -}
import           Result

{- The 'ParserCombinators' module implements some parser combinators, as
   covered in Week 08: -}
import           ParserCombinators


{- The 'readMaybe' function is for doing simple parsing of values. You
   won't need to use it directly, but the 'intOfString' and
   'stringOfInt' functions will be useful for doing Part 2 below. -}
import           Text.Read (readMaybe)

intOfString :: String -> Maybe Int
intOfString = readMaybe

stringOfInt :: Int -> String
stringOfInt = show

{------------------------------------------------------------------------}
{- Part 1 : CSV Files (25 marks)                                        -}
{------------------------------------------------------------------------}

{- This part involves outputing, filtering, and parsing CSV (comma
   separated values) files.
   A CSV file represented in memory consists of a header with some
   field names, and a list of records: -}

type CSVFile = (FieldNames, [CSVRecord])

{- where a record is a list of Strings: -}

type CSVRecord = [String]

{- and so are fieldnames: -}

type FieldNames = [String]

{- Here is an example 'database' of mountains in Scotland with their
   heights in metres: -}

mountains :: CSVFile
mountains =
  (  ["name",                  "height"],
   [ ["Ben Nevis",             "1345"]
   , ["Ben Macdui",            "1309"]
   , ["Braeriach",             "1296"]
   , ["Cairn Toul",            "1291"]
   , ["Sgor an Lochain Uaine", "1258"]
   , ["Cairn Gorm",            "1245"]
   , ["Aonach Beag",           "1234"]
   , ["Aonach Mòr",            "1220"]
   , ["Càrn Mòr Dearg",        "1220"]
   , ["Ben Lawers",            "1214"]
   , ["Beinn a' Bhùird",       "1197m"]
   , ["Beinn Mheadhoin",       "very, very high"]
   ])

{- Of course, as with any real world database, this database contains
   nonsense and needs to be cleaned. Here is a fixed version: -}

mountainsFixed :: CSVFile
mountainsFixed =
  (  ["name",                  "height"],
   [ ["Ben Nevis",             "1345"]
   , ["Ben Macdui",            "1309"]
   , ["Braeriach",             "1296"]
   , ["Cairn Toul",            "1291"]
   , ["Sgor an Lochain Uaine", "1258"]
   , ["Cairn Gorm",            "1245"]
   , ["Aonach Beag",           "1234"]
   , ["Aonach Mòr",            "1220"]
   , ["Càrn Mòr Dearg",        "1220"]
   , ["Ben Lawers",            "1214"]
   , ["Beinn a' Bhùird",       "1197"]
   , ["Beinn Mheadhoin",       "1183"]
   ])



{- 3.2.0 Printing CSV Files
   Write a function that converts a 'CSVFile' to a String as an actual
   comma separated file.
   For the purposes of this exercise, the format of a CSV file is:
   - A sequence of records, where each record is on a line terminated
     with either a newline ('\n', Unix-style) or a CRLF ('\r\n',
     Windows-style).
   - Each record consists of zero or more fields separated by commas
     (',')
   - Each field is either:
     - a sequence of non-comma and non-newline characters; or
     - zero or more spaces (which are ignored), a quoted string, and
       zero or more spaces (again ignored).
   The first record is taken to be the fieldnames, and the remaining
   records are normal data (so there must be at least one line).
   Note that there are choices when outputing strings as CSV
   fields. It is always safe to output them with quotes (as long as
   you quote any special characters like '"'s or newlines), but you
   will get more marks if you are selective about which fields you
   quote. For example, we could quote everything:
       > putStr (stringOfCSVFile mountains)
       "name","height"
       "Ben Nevis","1345"
       "Ben Macdui","1309"
       "Braeriach","1296"
       "Cairn Toul","1291"
       "Sgor an Lochain Uaine","1258"
       "Cairn Gorm","1245"
       "Aonach Beag","1234"
       "Aonach M\242r","1220"
       "C\224rn M\242r Dearg","1220"
       "Ben Lawers","1214"
       "Beinn a' Bh\249ird","1197m"
       "Beinn Mheadhoin","very, very high"
   or we could only quote things that need quoting:
       > putStr (stringOfCSVFile mountains)
       name,height
       Ben Nevis,1345
       Ben Macdui,1309
       Braeriach,1296
       Cairn Toul,1291
       Sgor an Lochain Uaine,1258
       Cairn Gorm,1245
       Aonach Beag,1234
       Aonach Mòr,1220
       Càrn Mòr Dearg,1220
       Ben Lawers,1214
       Beinn a' Bhùird,1197m
       Beinn Mheadhoin,"very, very high"
   HINTS:
   1. The easy way to quote a string is to use 'show'
   2. The function 'unlines' will turn a list of Strings into a list
      of strings separated by newline codes.
   3. 'intersperse' is a good way of putting things between other
      things in a list (see above).
   4. 'concat' will concatenate a list of strings into one string
-}



commaFinder :: String -> Bool
commaFinder (x:xs) 
   | x/=',' = commaFinder xs
   | otherwise = True
commaFinder [] = False

stringOfField :: String -> String
stringOfField string 
   | commaFinder string = show string
   | otherwise = string

stringOfCSVRecord :: CSVRecord -> String
stringOfCSVRecord [x] = stringOfField x
stringOfCSVRecord (x:xs) = stringOfField x ++ "," ++ stringOfCSVRecord xs
stringOfCSVRecord [] = []

stringOfCSVFile :: CSVFile -> String
stringOfCSVFile (fN:fNs,csvR:csvRs) = stringOfField fN ++ "," ++ stringOfCSVFile (fNs,csvR:csvRs)
stringOfCSVFile ([],csvR:csvRs) = "\n" ++ stringOfCSVRecord csvR ++ stringOfCSVFile ([],csvRs)
stringOfCSVFile ([],[]) = "\n"
stringOfCSVFile (x,y) = ""

{- 3.2.1 Filtering CSV Files
   Write two functions that take a height (as an 'Int') and 'CSVFile'
   value representing a list of mountains and returns the names of the
   mountains higher than that height.
   The functions are expecting to see a CSVFile where the records all
   have two fields, with the first field being the name and the second
   field containing the height in metres as an integer (represented as
   a String).
   The two functions differ in how they report anomalies in the input
   data.
   The first function returns a list of 'Result (String,Int)'
   values. For each record in the input:
   - If the record does not conform to the format described above,
     then there should be an 'Error "..."' in the output for that
     record.
   - If the record does conform, and the height is above the required
     height, then the name and height pair go into the output list.
   - If the record does conform, and the height is not above the
     required height, then nothing goes into the output for that
     record.
  For example:
     > mountainsOver1 1300 mountains
     [Ok ("Ben Nevis",1345),Ok ("Ben Macdui",1309),Error "...",Error "..."]
     > mountainsOver1 1300 mountainsFixed
     [Ok ("Ben Nevis",1345),Ok ("Ben Macdui",1309)]
  (you get to choose the error messages)
-}

strToResultInt :: String -> Result Int
strToResultInt string = case (readMaybe string :: Maybe Int) of {(Just x) -> Ok x; Nothing -> Error "notIntStr"}

strToInt :: String -> Int
strToInt x = read x :: Int

mountainsOver1 :: Int -> CSVFile -> [Result (String,Int)]
mountainsOver1 int (csvF,[mountain,height]:csvRs)
   | strToResultInt height == Error "notIntStr" = Error "This record could not be decoded":mountainsOver1 int (csvF,csvRs)
   | int < strToInt height = Ok (mountain, strToInt height):mountainsOver1 int (csvF,csvRs)
   | int >= strToInt height = mountainsOver1 int (csvF,csvRs)
   | otherwise = mountainsOver1 int (csvF,csvRs)
mountainsOver1 int (csvF,csvRs) = [] 

{- The second function reports an error if any of the records do not
   conform to the format described above. Otherwise, it returns 'Ok'
   with a list of the mountains that exceed the height. For example:

       > mountainsOver2 1300 mountains
       Error "..."

       > mountainsOver2 1300 mountainsFixed
       Ok [("Ben Nevis",1345),("Ben Macdui",1309)]
-}
mountainsOver2 :: Int -> CSVFile -> Result [(String,Int)]
mountainsOver2 int (csvF,csvR)
   | checkFile csvR = Ok (greaterHeights int csvR)
   | otherwise = Error "A record could not be decoded"

{- HINT: it is a good idea to write a separate function with the job of
   detecting whether or not a given CSVRecord is in the right format: 
-}

--mountainsOver2 Helper Functions:
greaterHeights :: Int -> [CSVRecord] -> [(String,Int)]
greaterHeights int ([mountain,height]:csvRs)
   | int < strToInt height = (mountain,strToInt height):greaterHeights int csvRs
   | otherwise = greaterHeights int csvRs
greaterHeights int x = []

checkFile :: [CSVRecord] -> Bool
checkFile (csvR:csvRs) = case decodeRecord csvR of {(Error x) -> False; (Ok x) -> checkFile csvRs}
checkFile [] = True

decodeRecord :: CSVRecord -> Result (String, Int)
decodeRecord [mountain,height] = case strToResultInt height of {(Ok x) -> Ok (mountain,strToInt height); (Error x) -> Error x}
decodeRecord record = Error "This function is expecting a CSVRecord with 2 values, it has possibly been implemented incorrectly."

{- 10 MARKS -}


{- 3.2.2 Parsing CSV Files
   Write a parser for CSV Files using the Parser combinators in the
   ParserCombinators module. The file format was described above. -}
{-
-}

notCommaOrNewline :: Parser Char
notCommaOrNewline =
  do 
     c <- char
     case c of
       ','  -> failParse "fail"
       '\n' -> failParse "fail"
       c    -> return c

notCommaOrNewlines :: Parser String
notCommaOrNewlines = zeroOrMore notCommaOrNewline
      
quotedString2 :: Parser String
quotedString2 = 
   do orElse newline spaces
      string <- quotedString
      spaces
      return string

parseCSVField :: Parser String
parseCSVField = 
   do orElse newline spaces
      orElse quotedString2 notCommaOrNewlines
{--}
parseCSVRecord :: Parser CSVRecord
parseCSVRecord = sepBy comma parseCSVField

parseCSVFile :: Parser CSVFile
parseCSVFile = 
   do fieldnames <- parseCSVRecord
      records <- zeroOrMore parseCSVRecords 
      return (fieldnames,records)
   where parseCSVRecords =
            do records <- parseCSVRecord
               case records of
                  [[]] -> failParse "fail"
                  records -> return records


comma :: Parser ()
comma = isChar ','


{-
type CSVFile = (FieldNames, [CSVRecord])

{- where a record is a list of Strings: -}

type CSVRecord = [String]

{- and so are fieldnames: -}

type FieldNames = [String]
-}

{- HINT: Use the 'quotedString' parser in ParserCombinators to parse
   quoted strings. The parser 'spaces' recognises zero or more spaces. -}

{- Test cases: both of these should parse to give the same values as the
   'mountains' and 'mountainsFixed' above. -}

mountainsText :: String
mountainsText = "name,height\nBen Nevis,1345\nBen Macdui,1309\nBraeriach,1296\nCairn Toul,1291\nSgor an Lochain Uaine,1258\nCairn Gorm,1245\nAonach Beag,1234\nAonach M\242r,1220\nC\224rn M\242r Dearg,1220\nBen Lawers,1214\nBeinn a' Bh\249ird,1197m\nBeinn Mheadhoin,\"very, very high\"\n"

mountainsFixedText :: String
mountainsFixedText = "name,height\nBen Nevis,1345\nBen Macdui,1309\nBraeriach,1296\nCairn Toul,1291\nSgor an Lochain Uaine,1258\nCairn Gorm,1245\nAonach Beag,1234\nAonach M\242r,1220\nC\224rn M\242r Dearg,1220\nBen Lawers,1214\nBeinn a' Bh\249ird,1197\nBeinn Mheadhoin,1183\n"


{- 10 MARKS -}

{------------------------------------------------------------------------}
{- Part 2 : An Expression Language (25 marks)                           -}
{------------------------------------------------------------------------}

{- In this part, you will implement a little expression language that
   can be used to compute simple arithmetic or string manipulations
   and make decisions. It is a toy, but is designed to be the core of
   a language that could be used for writing queries in a database.
   We will define the structure of the language by a series of
   datatype definitions. The first defines the kinds of values that
   the language will process: -}

data Value
  = StringValue String
  | IntValue    Int
  | BoolValue   Bool
  deriving (Show, Eq)

{- So a value is either a string ('StringValue s'), an Int ('IntValue
   i'), or a boolean ('BoolValue b'). -}

{- The language has several primitive operations, listed as
   constructors of the following datatype: -}

data OperationName
  = Add
  | Subtract
  | Multiply
  | Divide
  | Equal
  | LessThan
  | StringOfInt
  | IntOfString
  | PrefixOf
  deriving (Show, Eq)

{- We will define the meaning of these operations below, but for now the
   following function outputs the text version of each operation name: -}

prettyOperationName :: OperationName -> String
prettyOperationName Add         = "+"
prettyOperationName Subtract    = "-"
prettyOperationName Multiply    = "*"
prettyOperationName Divide      = "/"
prettyOperationName Equal       = "=="
prettyOperationName LessThan    = "<"
prettyOperationName StringOfInt = "stringOfInt"
prettyOperationName IntOfString = "intOfString"
prettyOperationName PrefixOf    = "prefixOf"

{- The expressions of the little language are as follows:
   - 'Value v' represents literal values (strings, ints, bools)
   - 'Var nm' represents a use of the variable 'nm'
   - 'Opr op exprs' represents a use of the operation 'op' with
     arguments 'exprs'
   - 'IfThenElse condExpr thenExpr elseExpr' represents an
     "if-then-else" with condition 'condExpr' and then and else
     branches.
   The following datatype represents expressions: -}

data Expr
  = Value       Value
  | Var         String
  | Opr         OperationName [Expr]
  | IfThenElse  Expr Expr Expr
  deriving (Show, Eq)

{- Here is an example program written in this little language that
   returns the larger of two numbers 'x' and 'y', written as a value
   of type 'Expr': -}

maxExpr :: Expr
maxExpr = IfThenElse (Opr LessThan [Var "x", Var "y"])
                     (Var "y")
                     (Var "x")

{- Here is another program that adds 10 to 'x': -}

addTenExpr :: Expr
addTenExpr = Opr Add [Var "x", Value (IntValue 10)]

{- And another that asks if 'Ben' is a prefix of the value stored in
   'name': -}

startsWithBenExpr :: Expr
startsWithBenExpr = Opr PrefixOf [Value (StringValue "Ben"), Var "name"]



{- The following function 'pretty prints' values of type 'Expr' in so
   called 's-expression' format. The main feature of this format is
   that operation names always appear before their arguments. See the
   examples below. You will be writing a parser for this format
   below. -}

prettyPrint :: Expr -> String
prettyPrint (Value (StringValue s)) = show s
prettyPrint (Value (IntValue i))    = show i
prettyPrint (Value (BoolValue b))   = show b
prettyPrint (Var v)                 = v
prettyPrint (Opr op [])             = "(" ++ prettyOperationName op ++ ")"
prettyPrint (Opr op exprs)          = "(" ++ prettyOperationName op ++ " " ++ concat (intersperse " " (map prettyPrint exprs)) ++ ")"
prettyPrint (IfThenElse cE tE eE)   = "(if " ++ prettyPrint cE ++ " " ++ prettyPrint tE ++ " " ++ prettyPrint eE ++ ")"

{- For example:
       > prettyPrint maxExpr
       "(if (< x y) y x)"
       > prettyPrint addTenExpr
        
       > prettyPrint startsWithBenExpr
       "(prefixOf \"Ben\" name)"
-}


{- 3.1.0 A small program
   Write a small program (as a value of type Expr) that is the
   equivalent of the following Haskell program:
     if intOfString x < intOfString y then "x is less than y" else "x is equal to or greater than y"
   You should have:
     > prettyPrint compareXandY
     "(if (< (intOfString x) (intOfString y)) \"x is less than y\" \"x is equal to or greater than y\")"

maxExpr :: Expr
maxExpr = IfThenElse (Opr LessThan [Var "x", Var "y"])
                     (Var "y")
                     (Var "x")
addTenExpr :: Expr
addTenExpr = Opr Add [Var "x", Value (IntValue 10)]
-}

compareXandY :: Expr
compareXandY = IfThenElse (Opr LessThan [Opr IntOfString [Var "x"], Opr IntOfString [Var "y"]])
                          (Value (StringValue "x is less than y"))
                          (Value (StringValue "x is equal to or greater than y"))


{- 5 MARKS -}


{- 3.1.1 An Evaluator
   Complete the implementations of 'evalOperation' and 'eval' to
   evaluate 'Expr's.
   The 'evalOperation' function takes an operation name and a list of
   values and either outputs the result of the operation on those
   values, or reports an error. The intended meaning of each of the
   operations is as follows:
   - 'Add' adds two integer values
   - 'Subtract' subtracts the second integer value from the first
   - 'Multiply' multiplies two integer values
   - 'Divide' divides the first integer value by the second (unless the second is 0, in which case it reports an error)
   - 'Equal' compares two values for equality, and returns a Boolean value
   - 'LessThan' returns 'True' if the first integer value is less than the second
   - 'StringOfInt' converts an integer argument to a string
   - 'IntOfString' converts a string argument to an integer
   - 'PrefixOf' checks to see if the first string value is a
   Some test cases:
      evalOperation Add [IntValue 1, IntValue 2]             == Ok (IntValue 3)
      evalOperation Add [IntValue 1, IntValue 2, IntValue 2] == Error "..."
      .. FIXME: add more ...
-}

evalOperation :: OperationName -> [Value] -> Result Value
evalOperation opr [IntValue x,IntValue y]
   | opr==Add = Ok (IntValue (x+y))
   | opr==Subtract = Ok (IntValue (x-y))
   | opr==Multiply = Ok (IntValue (x*y))
   | opr==Divide = if y==0 then Error "Division by zero is not possible" else Ok (IntValue (div x y))
   | opr==Equal = Ok (BoolValue (x==y))
   | opr==LessThan = Ok (BoolValue (x<y))
   | otherwise = Error "The StringOfInt, IntOfString, and PrefixOf operations cannot be done on 2 integer values"
evalOperation opr [IntValue x]
   | opr==StringOfInt = Ok (StringValue (stringOfInt x))
   | otherwise = Error "The only operation that can be applied to 1 integer value is StringOfInt"
evalOperation opr [StringValue x]
   | opr==IntOfString = case intOfString x of {Nothing -> Error "You have inputted a string that contains non integer characters"; Just y -> Ok (IntValue y)}
   | otherwise = Error "The only operation that can be applied to 1 string value is IntOfString"
evalOperation opr [StringValue x,StringValue y]
   | opr==PrefixOf = Ok (BoolValue (x `isPrefixOf` y))
   | otherwise = Error "The only operation that can be applied to 2 string values is PrefixOf"
evalOperation opr values 
   | opr `elem` [Add,Subtract,Multiply,Divide,Equal,LessThan] = Error "This operation requires no more or less than 2 integer inputs"
   | opr==StringOfInt = Error "This operation requires no more or less than 1 integer input"
   | opr==IntOfString = Error "This operation requires no more or less than 1 string input"
   | opr==PrefixOf = Error "This operation requires no more or less than 2 string inputs"
   | otherwise = Error "unknown error"

{- The 'eval' function takes an environment (a key/value store with
   variable names as keys) and an 'Expr' and evaluates the 'expr' to a
   value. The intended meaning is as follows:
   - 'Value v' evaluates to the value 'v'
   - 'Var varname' looks up the variable 'varname' in the environment
   - 'Opr op exprs' evaluates all the expressions 'exprs' to values,
     and then calls 'evalOperation' to evaluate the operation 'op' on
     those values.
   - 'IfThenElse condExpr thenExpr elseExpr' evaluates 'condExpr':
     - if it returns the boolean value 'True', then it evaluates
       'thenExpr' (and returns the result)
     - if it returns the boolean value 'False', then it evaluates
       'elseExpr' (and returns the result)
   To look up variables in the context, you will need to define
   'lookupEnv' first.
   Some test cases:
      eval [] (Value (StringValue "x"))                                    == Ok (StringValue "x")
      eval [] (Var "x")                                                    == Error "..."
      eval [("x",StringValue "123")] (Var "x")                             == Ok (StringValue "123")
      eval [("x",IntValue 1),("y",IntValue 2)] (Opr Add [Var "x",Var "y"]) == Ok (IntValue 3)
      eval [("x",IntValue 1),("y",IntValue 2)] (Opr Add [Var "x",Var "z"]) == Error "..."
      eval [("x",IntValue 1),("y",IntValue 2)] (IfThenElse (Value (BoolValue True)) (Opr Add [Var "x",Var "y"]) (Opr Subtract [Var "x",Var "y"]))
      eval 
-}
eval :: [(String,Value)] -> Expr -> Result Value
eval kvs (Value v) = Ok v
eval kvs (Var varname) = lookupEnv varname kvs
eval kvs (Opr op exprs) = case mapM (eval kvs) exprs of {Ok x -> evalOperation op x; Error x -> Error x}
eval kvs (IfThenElse condExpr thenExpr elseExpr) = if eval kvs condExpr == Ok (BoolValue True) then eval kvs thenExpr else eval kvs elseExpr

lookupEnv :: String -> [(String,Value)] -> Result Value
lookupEnv str ((key,value):kvs)
   | str==key = Ok value
   | otherwise = lookupEnv str kvs
lookupEnv str [] = Error "No value was found under that variable name"

{-

 -}

{- 10 MARKS -}

{- 3.1.2 A Parser
   Write a parser for 'Expr's, following this grammar:
   <expr> ::= <identifier>             => Var
            | <quotedString>           => Value (StringValue s)
            | <number>                 => Value (IntValue s)
            | "True"                   => Value (BoolValue True)
            | "False"                  => Value (BoolValue False)
            | "(" <spaces> <operationName> (<spaces> <expr>)* <spaces> ")"                   => Opr op exprs
            | "(" <spaces> "if" <spaces> <expr> <spaces> <expr> <spaces> <expr> <spaces> ")" => If condExpr thenExpr elseExpr
   <operationName> ::= "+"            => Add
                     | "-"            => Subtract
                     | "*"            => Multiply
                     | "/"            => Divide
                     | "=="           => Equal
                     | "<"            => LessThan
                     | "stringOfInt"  => StringOfInt
                     | "intOfString"  => IntOfString
                     | "prefixOf"     => PrefixOf
   where the following are defined for you:
     <spaces>         means zero or more space characters
     <identifier>     means a Haskell or Java style variable name
     <quotedString>   means a quoted string "like this"
     <number>         means a one or more decimal digits
   The parser should be able to parse anything that 'prettyPrint'
   outputs:
       > runParser parseExpr (prettyPrint maxExpr) == Ok (maxExpr, "")
       True
       > runParser parseExpr (prettyPrint addTenExpr) == Ok (addTenExpr, "")
       True
       > runParser parseExpr (prettyPrint startsWithBenExpr) == Ok (startsWithBenExpr, "")
       True
       > runParser parseExpr (prettyPrint compareXandY) == Ok (compareXandY, "")
       True
-}
parseExpr :: Parser Expr
parseExpr = orElse (orElse parseVar parseValueExpr) (orElse parseOpr parseIfThenElse)

parseOperationName :: Parser OperationName
parseOperationName =
   do c <- char 
      case c of
         '+' -> return Add
         '-' -> return Subtract
         '*' -> return Multiply
         '/' -> return Divide
         '<' -> return LessThan
         '=' -> 
            do isString "="
               return Equal
         's' ->
            do isString "tringOfInt"
               return StringOfInt
         'i' -> 
            do isString "ntOfString"
               return IntOfString
         'p' -> 
            do isString "refixOf"
               return PrefixOf 
         c -> failParse "invalid operation"

parseValue :: Parser Value
parseValue = orElse parseBValue (orElse parseIntValue parseQstrValue)

parseValueExpr :: Parser Expr
parseValueExpr =
   do value <- parseValue
      return (Value value)

parseIfThenElse :: Parser Expr
parseIfThenElse =
   do orElse (isChar '(') (isChar ')')
      spaces 
      c <- char
      case c of
         'i' ->
               do isChar 'f'
                  spaces
                  condExpr <- parseExpr
                  spaces
                  thenExpr <- parseExpr
                  spaces
                  elseExpr <- parseExpr
                  spaces
                  orElse (isChar '(') (isChar ')')
                  return (IfThenElse condExpr thenExpr elseExpr)
         c ->  failParse "invalid input"

parseOpr :: Parser Expr 
parseOpr = 
   do orElse (isChar '(') spaces 
      spaces
      op <- parseOperationName
      exprs <- (do spaces; sepBy spaces parseExpr)
      spaces
      orElse (isChar '(') (isChar ')')
      return (Opr op exprs)

parseVar :: Parser Expr
parseVar = 
   do string <- identifier
      return (Var string)

spaceChar :: Parser Char
spaceChar = 
   do c <- char 
      case c of
         ' ' -> failParse "expecting a non space"
         c -> return c

spaceChars :: Parser String 
spaceChars = zeroOrMore spaceChar

parseBValue :: Parser Value
parseBValue =
   do string <- spaceChars
      case string of
         "True" -> return (BoolValue True)
         "False" -> return (BoolValue False)
         string -> failParse "Expecting True or False represented in a string"

parseQstrValue :: Parser Value
parseQstrValue = 
   do string <- quotedString
      return (StringValue string)

strDigit :: Parser Char
strDigit = 
   do 
      spaces
      c <- char
      case intOfString [c] of
         Just x -> return c
         Nothing -> failParse "expecting an integer represented in a string"

strNumber :: Parser String
strNumber = zeroOrMore strDigit   

parseIntValue :: Parser Value
parseIntValue =
   do 
      string <- strNumber
      case strToResultInt string of
         Ok x -> return (IntValue (strToInt string))
         Error x -> failParse "Expecting an integer represented in a string"


{- 10 MARKS -}

{------------------------------------------------------------------------}
{- Part 3 : Mini-project (30 marks)                                     -}
{------------------------------------------------------------------------}

{- 3.3 Command line tool for CSV Files
   Write a command line tool for filtering CSV Files using expressions
   written in the little expression language.
   Edit the file 'Ex3Main.hs' (which imports this one) to implement
   your tool using the functions you wrote in this file.
   An example (possible) use:
      $ stack build
      $ stack exec Ex3 '(if (< (intOfString height) 1300) False True)' exercises/mountainsFixed.csv
      name,height
      Ben Nevis,1345
      Ben Macdui,1309
      $ stack exec Ex3 '(< (intOfString height) 1300)' exercises/mountainsFixed.csv
      name,height
      Braeriach,1296
      Cairn Toul,1291
      Sgor an Lochain Uaine,1258
      Cairn Gorm,1245
      Aonach Beag,1234
      Aonach Mòr,1220
      Càrn Mòr Dearg,1220
      Ben Lawers,1214
      Beinn a' Bhùird,1197
      Beinn Mheadhoin,1183
      $ stack exec Ex3 '(< (intOfString height) 1300)' exercises/mountains.csv
      ERROR: Not an integer: 1197m
   The tool should have the following basic features:
   1. Take the expression and CSV filename on the command line
   2. Parse the expression
   3. Read in and parse the CSV file
   4. Filter the CSV file using the expression; the fields of the CSV
      file ought to be mapped to variables in the expression.
   5. Print out the filtered CSV file, or save it to a file.
   A basic implementation of the above will get you 10 marks. To get
   the rest, implement some other features, such as:
   - Selecting fields to output
   - Aggregation (e.g. summing up the results of some expression)
   - Generating another output format (e.g., HTML tables)
   - Inputing multiple CSV Files and joining them (as in a relational
     database join).
-}


{- 30 MARKS -}


{------------------------------------------------------------------------}
{- END OF EXERCISE                                                      -}
{------------------------------------------------------------------------}
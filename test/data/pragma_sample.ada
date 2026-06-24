--  pragma_sample.ada: static fixture for From_File tests.
--
--  A comment containing pragma Sample_Pragma (Ignored, "yes") should not
--  be parsed.

with Ada.Text_IO;

pragma Sample_Pragma (Name,    "hello from file");
pragma Sample_Pragma (Count,   42);
pragma Sample_Pragma (Ratio,   1.5);
pragma Sample_Pragma (Enabled, True);
pragma Other_Pragma  (Tag,     "another pragma");
pragma Empty_Pragma;

--  The procedure declaration below stops the scanner; everything
--  after it must be silently ignored.

procedure Sample_Body is
   pragma Sample_Pragma (Ignored, "after unit decl");
begin
   null;
end Sample_Body;

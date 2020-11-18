<?xml version="1.0" encoding="UTF-8"?>
<Project Version="1" Path="D:/Projects/HGA101_GPU/Anlogic/HGA101_GPU">
    <Project_Created_Time>2020-11-14 16:05:26</Project_Created_Time>
    <TD_Version>5.0.24224</TD_Version>
    <UCode>00000000</UCode>
    <Name>HGA101_GPU</Name>
    <HardWare>
        <Family>EG4</Family>
        <Device>EG4D20EG176</Device>
    </HardWare>
    <Source_Files>
        <Verilog>
            <File Path="../../RTL/CPU/EX/VPU/IALU_16.V">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true"/>
                    <Attr Name="UsedInP&R" Val="true"/>
                    <Attr Name="BelongTo" Val="design_1"/>
                    <Attr Name="CompileOrder" Val="4"/>
                </FileInfo>
            </File>
        </Verilog>
        <Header>
            <File Path="../../RTL/CPU/EX/cnrv_FPU_ip/R5FP_inc.vh">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true"/>
                    <Attr Name="UsedInP&R" Val="true"/>
                    <Attr Name="BelongTo" Val="design_1"/>
                    <Attr Name="CompileOrder" Val="3"/>
                </FileInfo>
            </File>
            <File Path="../../RTL/CPU/R5FP_inc.vh">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true"/>
                    <Attr Name="UsedInP&R" Val="true"/>
                    <Attr Name="BelongTo" Val="design_1"/>
                    <Attr Name="CompileOrder" Val="1"/>
                </FileInfo>
            </File>
            <File Path="../../RTL/CPU/global_defines.vh">
                <FileInfo>
                    <Attr Name="UsedInSyn" Val="true"/>
                    <Attr Name="UsedInP&R" Val="true"/>
                    <Attr Name="BelongTo" Val="design_1"/>
                    <Attr Name="CompileOrder" Val="2"/>
                </FileInfo>
            </File>
        </Header>
    </Source_Files>
    <FileSets>
        <FileSet Name="constrain_1" Type="ConstrainFiles">
        </FileSet>
        <FileSet Name="design_1" Type="DesignFiles">
        </FileSet>
    </FileSets>
    <TOP_MODULE>
        <LABEL></LABEL>
        <MODULE></MODULE>
        <CREATEINDEX>auto</CREATEINDEX>
    </TOP_MODULE>
    <Property>
    </Property>
    <Device_Settings>
    </Device_Settings>
    <Configurations>
    </Configurations>
    <Project_Settings>
        <Step_Last_Change>2020-11-14 16:21:49.820</Step_Last_Change>
        <Current_Step>10</Current_Step>
        <Step_Status>true</Step_Status>
    </Project_Settings>
</Project>

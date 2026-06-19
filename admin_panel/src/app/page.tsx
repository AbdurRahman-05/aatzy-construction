'use client';

import React, { useState } from 'react';
import Link from 'next/link';

export default function PortfolioLandingPage() {
  const [activeTab, setActiveTab] = useState<'tracker' | 'quotes' | 'b2b'>('tracker');
  
  // Interactive Simulator State
  const [tasks, setTasks] = useState([
    { id: 1, title: 'Soil Testing & Excavation', duration: 3, status: 'Completed', cost: 12000, hasPhoto: true },
    { id: 2, title: 'Foundation Footing & Pillars', duration: 7, status: 'Completed', cost: 45000, hasPhoto: true },
    { id: 3, title: 'Brickwork & Outer Walling', duration: 10, status: 'In Progress', cost: 38000, hasPhoto: false },
    { id: 4, title: 'Electrical & Plumbing Conduit Layout', duration: 5, status: 'Todo', cost: 15000, hasPhoto: false },
    { id: 5, title: 'Plastering & Wall Finishing', duration: 6, status: 'Todo', cost: 22000, hasPhoto: false },
  ]);

  const toggleTaskStatus = (id: number) => {
    setTasks(tasks.map(task => {
      if (task.id === id) {
        let newStatus = 'Todo';
        if (task.status === 'Todo') newStatus = 'In Progress';
        else if (task.status === 'In Progress') newStatus = 'Completed';
        return { 
          ...task, 
          status: newStatus,
          hasPhoto: newStatus === 'Completed' ? true : false
        };
      }
      return task;
    }));
  };

  const completedCount = tasks.filter(t => t.status === 'Completed').length;
  const progressPercent = Math.round((completedCount / tasks.length) * 100);
  const totalCost = tasks.reduce((sum, t) => sum + (t.status === 'Completed' ? t.cost : t.status === 'In Progress' ? t.cost * 0.5 : 0), 0);

  return (
    <div className="min-h-screen bg-[#0B0F19] text-gray-100 font-sans selection:bg-amber-500 selection:text-black overflow-x-hidden">
      
      {/* Glow effects background */}
      <div className="absolute top-0 left-1/4 w-[500px] h-[500px] bg-blue-600/10 rounded-full blur-[120px] pointer-events-none"></div>
      <div className="absolute top-1/3 right-1/4 w-[600px] h-[600px] bg-amber-500/5 rounded-full blur-[150px] pointer-events-none"></div>
      <div className="absolute bottom-1/4 left-1/3 w-[400px] h-[400px] bg-indigo-600/10 rounded-full blur-[100px] pointer-events-none"></div>

      {/* Header / Nav */}
      <header className="sticky top-0 z-50 backdrop-blur-md bg-[#0B0F19]/70 border-b border-gray-800/80 px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="bg-gradient-to-r from-amber-500 to-amber-600 p-2.5 rounded-xl shadow-md shadow-amber-500/20">
              <svg className="w-5 h-5 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
            </div>
            <span className="text-xl font-black tracking-tight text-white">
              BuildConnect<span className="text-amber-500">.</span>
            </span>
          </div>

          <nav className="hidden md:flex items-center space-x-8 text-sm font-medium text-gray-400">
            <a href="#features" className="hover:text-white transition-colors">Features</a>
            <a href="#simulator" className="hover:text-white transition-colors">Interactive Demo</a>
            <a href="#problems" className="hover:text-white transition-colors">Industry Challenges</a>
            <a href="#about" className="hover:text-white transition-colors">About</a>
          </nav>

          <div className="flex items-center space-x-4">
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative pt-20 pb-24 px-6">
        <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          <div className="lg:col-span-7 space-y-8 text-center lg:text-left">
            <div className="inline-flex items-center space-x-2 bg-amber-500/10 border border-amber-500/20 px-3.5 py-1.5 rounded-full">
              <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></span>
              <span className="text-xs font-bold uppercase tracking-wider text-amber-400">Next-Gen Construction Technology</span>
            </div>
            
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black tracking-tight text-white leading-tight">
              Money, Material, <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-400 to-amber-600">Manpower & Assets</span><br />
              All in One Platform.
            </h1>

            <p className="text-gray-400 text-base sm:text-lg max-w-2xl mx-auto lg:mx-0 leading-relaxed">
              One central ecosystem for construction companies, contractors, and material suppliers. Delivering unmatched transparency, live progress audits, quote bidding analytics, and manpower payroll calculations.
            </p>

            <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4">
              <a 
                href="#simulator" 
                className="w-full sm:w-auto text-center bg-white text-gray-950 font-bold px-8 py-4 rounded-xl shadow-lg hover:bg-gray-100 hover:shadow-white/5 transition-all hover:scale-[1.03] active:scale-95 text-sm"
              >
                Try Interactive Demo
              </a>
            </div>

            <div className="pt-6 grid grid-cols-3 gap-6 max-w-md mx-auto lg:mx-0 border-t border-gray-800/80">
              <div>
                <p className="text-2xl font-black text-white">100%</p>
                <p className="text-xs text-gray-500 uppercase font-bold tracking-wider mt-1">Audit Trail</p>
              </div>
              <div>
                <p className="text-2xl font-black text-white">₹0</p>
                <p className="text-xs text-gray-500 uppercase font-bold tracking-wider mt-1">Manual Errors</p>
              </div>
              <div>
                <p className="text-2xl font-black text-white">Real-Time</p>
                <p className="text-xs text-gray-500 uppercase font-bold tracking-wider mt-1">Progress Sync</p>
              </div>
            </div>
          </div>

          {/* Hero Premium Visual Mockup */}
          <div className="lg:col-span-5 relative">
            <div className="absolute inset-0 bg-gradient-to-tr from-amber-500/20 to-blue-500/20 rounded-3xl blur-[30px] opacity-40"></div>
            <div className="relative bg-[#111827] border border-gray-800 rounded-3xl p-6 shadow-2xl">
              
              {/* App UI Header mockup */}
              <div className="flex justify-between items-center pb-4 border-b border-gray-800/80">
                <div className="flex items-center space-x-3">
                  <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-400 to-amber-600 flex items-center justify-center font-bold text-black text-sm">
                    BC
                  </div>
                  <div>
                    <h4 className="text-xs font-black text-white">Project #1092</h4>
                    <p className="text-[10px] text-gray-500">Greenwood Residential Villa</p>
                  </div>
                </div>
                <span className="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-[10px] font-bold px-2 py-0.5 rounded-full uppercase">
                  Active
                </span>
              </div>

              {/* Progress Ring / Dashboard mock card */}
              <div className="bg-[#1F2937]/50 rounded-2xl p-4 border border-gray-800/60 mt-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs text-gray-400 font-bold">Execution Progress</span>
                  <span className="text-xs text-amber-500 font-bold">78% Done</span>
                </div>
                <div className="w-full bg-gray-800 h-2 rounded-full overflow-hidden">
                  <div className="bg-gradient-to-r from-amber-400 to-amber-500 h-2 rounded-full" style={{ width: '78%' }}></div>
                </div>
                
                <div className="grid grid-cols-2 gap-4 mt-4 pt-4 border-t border-gray-800/40">
                  <div>
                    <p className="text-[10px] text-gray-500">Quoted Budget</p>
                    <p className="text-sm font-black text-white">₹14.80 Lakhs</p>
                  </div>
                  <div>
                    <p className="text-[10px] text-gray-500">Actual Cost Incurred</p>
                    <p className="text-sm font-black text-amber-500">₹11.20 Lakhs</p>
                  </div>
                </div>
              </div>

              {/* Chat Update mockup */}
              <div className="space-y-3 mt-4">
                <div className="flex items-start space-x-3 text-xs bg-[#1F2937]/30 p-3 rounded-xl border border-gray-800/30">
                  <div className="w-6 h-6 rounded-full bg-blue-500 text-white flex items-center justify-center font-bold text-[10px]">
                    K
                  </div>
                  <div className="flex-1">
                    <div className="flex justify-between">
                      <span className="font-bold text-gray-300 text-[11px]">Karan Builders (Provider)</span>
                      <span className="text-[9px] text-gray-500">2 mins ago</span>
                    </div>
                    <p className="text-gray-400 text-[10px] mt-0.5">Uploaded proof of completion photo for foundation concrete. Ready for stage audit.</p>
                  </div>
                </div>

                <div className="flex items-center space-x-3 bg-amber-500/10 border border-amber-500/20 p-2.5 rounded-xl">
                  <svg className="w-4 h-4 text-amber-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  </svg>
                  <span className="text-[10px] text-amber-400 font-bold">1 proof photo attached • Tap to verify work</span>
                </div>
              </div>
            </div>
          </div>

        </div>
      </section>

      {/* Main Issues Section */}
      <section id="problems" className="py-20 bg-[#0F1524] border-y border-gray-800/40 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
            <h2 className="text-xs font-bold text-amber-500 uppercase tracking-widest">The Challenge</h2>
            <h3 className="text-3xl sm:text-4xl font-black text-white">Major Bottlenecks in Today's Construction Industry</h3>
            <p className="text-gray-400 text-sm sm:text-base leading-relaxed">
              Juggling manual updates, phone messaging logs, paper bills, and opaque contractor claims pushes construction projects past deadlines and over budget.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <div className="bg-[#111827] border border-gray-850 p-6 rounded-2xl hover:border-amber-500/20 transition-all group">
              <div className="w-12 h-12 rounded-xl bg-red-500/10 border border-red-500/20 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <svg className="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <h4 className="text-lg font-bold text-white mb-2">Fragmented Systems</h4>
              <p className="text-gray-400 text-sm leading-relaxed">
                Juggling multiple WhatsApp groups, spreadsheets, and invoices leads to continuous miscommunication and costly errors.
              </p>
            </div>

            <div className="bg-[#111827] border border-gray-850 p-6 rounded-2xl hover:border-amber-500/20 transition-all group">
              <div className="w-12 h-12 rounded-xl bg-red-500/10 border border-red-500/20 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <svg className="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h4 className="text-lg font-bold text-white mb-2">Cost Overruns</h4>
              <p className="text-gray-400 text-sm leading-relaxed">
                Unplanned material expenses, untracked worker hours, and lack of visual proof lead to unchecked cash leaks.
              </p>
            </div>

            <div className="bg-[#111827] border border-gray-850 p-6 rounded-2xl hover:border-amber-500/20 transition-all group">
              <div className="w-12 h-12 rounded-xl bg-red-500/10 border border-red-500/20 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <svg className="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </div>
              <h4 className="text-lg font-bold text-white mb-2">Workforce Bottlenecks</h4>
              <p className="text-gray-400 text-sm leading-relaxed">
                Manual register attendance and uncalculated daily wages create continuous friction in managing large workforces.
              </p>
            </div>

            <div className="bg-[#111827] border border-gray-850 p-6 rounded-2xl hover:border-amber-500/20 transition-all group">
              <div className="w-12 h-12 rounded-xl bg-red-500/10 border border-red-500/20 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <svg className="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                </svg>
              </div>
              <h4 className="text-lg font-bold text-white mb-2">Material Delays</h4>
              <p className="text-gray-400 text-sm leading-relaxed">
                Opaque procurement processes, slow order requests, and disconnected local dealers halt construction workflows.
              </p>
            </div>

            <div className="bg-[#111827] border border-gray-850 p-6 rounded-2xl hover:border-amber-500/20 transition-all group">
              <div className="w-12 h-12 rounded-xl bg-red-500/10 border border-red-500/20 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <svg className="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h4 className="text-lg font-bold text-white mb-2">Opaque Progress Audits</h4>
              <p className="text-gray-400 text-sm leading-relaxed">
                No visual evidence of completed steps requires continuous manual inspection to release next-stage funds.
              </p>
            </div>

            <div className="bg-[#111827] border border-gray-850 p-6 rounded-2xl hover:border-amber-500/20 transition-all group">
              <div className="w-12 h-12 rounded-xl bg-red-500/10 border border-red-500/20 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <svg className="w-6 h-6 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <h4 className="text-lg font-bold text-white mb-2">Bid Manipulation</h4>
              <p className="text-gray-400 text-sm leading-relaxed">
                Opaque bidding and raw estimate spreadsheets leave project owners exposed to cost inflation.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Interactive Live Simulator Section */}
      <section id="simulator" className="py-20 px-6 relative">
        <div className="max-w-7xl mx-auto">
          <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
            <h2 className="text-xs font-bold text-amber-500 uppercase tracking-widest">Experience It Live</h2>
            <h3 className="text-3xl sm:text-4xl font-black text-white">Click, Mark, & Monitor the Construction Progress</h3>
            <p className="text-gray-400 text-sm sm:text-base">
              Try out our interactive dashboard prototype below. Tap status pill buttons to toggle task completion status and see how the budget and live progress audits sync.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-stretch">
            
            {/* Control Dashboard Panel */}
            <div className="lg:col-span-8 bg-[#111827] border border-gray-800 rounded-3xl p-6 flex flex-col justify-between shadow-2xl">
              <div>
                <div className="flex justify-between items-center mb-6">
                  <div>
                    <h4 className="text-base font-bold text-white">Project Gantt & Tasks List</h4>
                    <p className="text-xs text-gray-500">Tap status button to advance task progress</p>
                  </div>
                  <span className="bg-amber-500/10 text-amber-400 border border-amber-500/20 text-xs font-bold px-3 py-1 rounded-full">
                    {completedCount} / {tasks.length} Steps Completed
                  </span>
                </div>

                <div className="space-y-3">
                  {tasks.map(task => (
                    <div key={task.id} className="flex flex-col sm:flex-row sm:items-center justify-between p-4 bg-[#1F2937]/30 border border-gray-800/50 rounded-2xl hover:border-gray-700/80 transition-all">
                      <div className="flex items-start space-x-3">
                        <div className={`mt-0.5 w-5 h-5 rounded-full flex items-center justify-center ${task.status === 'Completed' ? 'bg-emerald-500/20 text-emerald-400' : task.status === 'In Progress' ? 'bg-blue-500/20 text-blue-400' : 'bg-gray-800 text-gray-600'}`}>
                          {task.status === 'Completed' ? (
                            <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M5 13l4 4L19 7" />
                            </svg>
                          ) : (
                            <span className="text-[10px] font-bold">{task.id}</span>
                          )}
                        </div>
                        <div>
                          <p className={`text-sm font-bold text-gray-200 ${task.status === 'Completed' ? 'line-through text-gray-500' : ''}`}>
                            {task.title}
                          </p>
                          <p className="text-[10px] text-gray-500 mt-0.5">Est. Duration: {task.duration} days • Value: ₹{task.cost.toLocaleString()}</p>
                        </div>
                      </div>

                      <div className="flex items-center space-x-3 mt-3 sm:mt-0 justify-end">
                        {task.hasPhoto && (
                          <span className="flex items-center text-[10px] font-bold text-emerald-400 bg-emerald-500/10 border border-emerald-500/20 px-2 py-0.5 rounded-full">
                            <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                            </svg>
                            Photo Attached
                          </span>
                        )}
                        <button
                          onClick={() => toggleTaskStatus(task.id)}
                          className={`text-xs font-extrabold px-3 py-1.5 rounded-lg transition-all ${
                            task.status === 'Completed'
                              ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
                              : task.status === 'In Progress'
                              ? 'bg-blue-600 text-white hover:bg-blue-700'
                              : 'bg-gray-800 text-gray-400 hover:bg-gray-700 hover:text-white'
                          }`}
                        >
                          {task.status}
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="mt-6 pt-6 border-t border-gray-800 flex items-center space-x-2 text-xs text-gray-500">
                <svg className="w-4 h-4 text-amber-500 animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>Interactive Concept Prototype. Full capabilities are accessible in the Android and iOS app downloads.</span>
              </div>
            </div>

            {/* Simulated Live Analytics Output */}
            <div className="lg:col-span-4 bg-gradient-to-b from-[#111827] to-[#0B0F19] border border-gray-800 rounded-3xl p-6 shadow-2xl flex flex-col justify-between">
              <div className="space-y-6">
                <div className="pb-4 border-b border-gray-800">
                  <h4 className="text-sm font-black text-white uppercase tracking-wider">Live Budget Analytics</h4>
                  <p className="text-xs text-gray-500">Calculated from completed task values</p>
                </div>

                {/* Progress Wheel representation */}
                <div className="flex flex-col items-center py-4">
                  <div className="relative w-36 h-36 flex items-center justify-center">
                    {/* SVG Progress Circle */}
                    <svg className="w-full h-full transform -rotate-90">
                      <circle cx="72" cy="72" r="62" stroke="#1F2937" strokeWidth="12" fill="transparent" />
                      <circle cx="72" cy="72" r="62" stroke="#F59E0B" strokeWidth="12" fill="transparent" 
                        strokeDasharray={2 * Math.PI * 62}
                        strokeDashoffset={2 * Math.PI * 62 * (1 - progressPercent / 100)}
                        strokeLinecap="round"
                        className="transition-all duration-700 ease-out"
                      />
                    </svg>
                    <div className="absolute flex flex-col items-center">
                      <span className="text-3xl font-black text-white">{progressPercent}%</span>
                      <span className="text-[10px] text-gray-500 uppercase font-black tracking-wider">Progress</span>
                    </div>
                  </div>
                </div>

                <div className="space-y-3">
                  <div className="flex justify-between items-center text-xs p-3 bg-gray-900/40 rounded-xl">
                    <span className="text-gray-400 font-bold">Total Estimated Budget</span>
                    <span className="font-extrabold text-white">₹1,39,000</span>
                  </div>
                  <div className="flex justify-between items-center text-xs p-3 bg-gray-900/40 rounded-xl">
                    <span className="text-gray-400 font-bold">Actual Cost Disbursed</span>
                    <span className="font-extrabold text-amber-500">₹{totalCost.toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between items-center text-xs p-3 bg-gray-900/40 rounded-xl">
                    <span className="text-gray-400 font-bold">Project Audit Health</span>
                    <span className={`font-extrabold ${progressPercent > 60 ? 'text-emerald-400' : progressPercent > 20 ? 'text-amber-400' : 'text-orange-400'}`}>
                      {progressPercent > 60 ? 'Optimized' : progressPercent > 20 ? 'Good' : 'Initiating'}
                    </span>
                  </div>
                </div>
              </div>

              <div className="mt-8">
                <div className="w-full text-center bg-[#1F2937]/50 text-gray-400 font-bold py-3.5 rounded-xl text-xs border border-gray-800/80">
                  Data Stream Synced
                </div>
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* Key Features Grid */}
      <section id="features" className="py-20 bg-[#0F1524] border-t border-gray-800/40 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
            <h2 className="text-xs font-bold text-amber-500 uppercase tracking-widest">Our Ecosystem</h2>
            <h3 className="text-3xl sm:text-4xl font-black text-white">Everything You Need to Run Projects & Materials</h3>
            <p className="text-gray-400 text-sm sm:text-base">
              Explore the four core modules designed to digitalize site project supervision, worker wages, bidding quotes, and supplier catalog sales.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="bg-[#111827] border border-gray-800 p-8 rounded-3xl hover:border-amber-500/20 transition-all flex flex-col justify-between">
              <div>
                <div className="w-12 h-12 rounded-2xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center mb-6">
                  <svg className="w-6 h-6 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
                  </svg>
                </div>
                <h4 className="text-xl font-bold text-white mb-2">Real-Time Task Tracking</h4>
                <p className="text-gray-400 text-sm leading-relaxed mb-6">
                  Break down your project into stages (Excavation, Structure, Masonry, Plumbing). Contractors update tasks directly from the field with base64 proof of completion photos, generating a secure audit trail before payments are cleared.
                </p>
              </div>
              <ul className="text-xs text-gray-500 space-y-2 border-t border-gray-800/50 pt-4">
                <li className="flex items-center"><span className="w-1.5 h-1.5 bg-amber-500 rounded-full mr-2"></span> Stage-wise breakdown with Gantt-like timeline</li>
                <li className="flex items-center"><span className="w-1.5 h-1.5 bg-amber-500 rounded-full mr-2"></span> Photo-verified completion uploads</li>
              </ul>
            </div>

            <div className="bg-[#111827] border border-gray-800 p-8 rounded-3xl hover:border-amber-500/20 transition-all flex flex-col justify-between">
              <div>
                <div className="w-12 h-12 rounded-2xl bg-blue-500/10 border border-blue-500/20 flex items-center justify-center mb-6">
                  <svg className="w-6 h-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                </div>
                <h4 className="text-xl font-bold text-white mb-2">Detailed Quote Comparisons</h4>
                <p className="text-gray-400 text-sm leading-relaxed mb-6">
                  Post project requirements and receive granular bids detailing material quality, labor metrics, and duration. Our algorithmic sidebar comparison highlights cost discrepancies and profit margins instantly to prevent bid rigging.
                </p>
              </div>
              <ul className="text-xs text-gray-500 space-y-2 border-t border-gray-800/50 pt-4">
                <li className="flex items-center"><span className="w-1.5 h-1.5 bg-blue-400 rounded-full mr-2"></span> Side-by-side granular material comparison</li>
                <li className="flex items-center"><span className="w-1.5 h-1.5 bg-blue-400 rounded-full mr-2"></span> Algorithmic cost anomaly identification</li>
              </ul>
            </div>

            <div className="bg-[#111827] border border-gray-800 p-8 rounded-3xl hover:border-amber-500/20 transition-all flex flex-col justify-between">
              <div>
                <div className="w-12 h-12 rounded-2xl bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center mb-6">
                  <svg className="w-6 h-6 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                  </svg>
                </div>
                <h4 className="text-xl font-bold text-white mb-2">B2B Material Procurement</h4>
                <p className="text-gray-400 text-sm leading-relaxed mb-6">
                  Access catalog pricing for cement, steel, bricks, and wiring. BuildMart allows contractors to request quotes directly from verified manufacturers, cutting middlemen markups and managing delivery schedules in the tracking logs.
                </p>
              </div>
              <ul className="text-xs text-gray-500 space-y-2 border-t border-gray-800/50 pt-4">
                <li className="flex items-center"><span className="w-1.5 h-1.5 bg-indigo-400 rounded-full mr-2"></span> Verified supplier ratings & certifications</li>
                <li className="flex items-center"><span className="w-1.5 h-1.5 bg-indigo-400 rounded-full mr-2"></span> Direct inquiry generation system</li>
              </ul>
            </div>

            <div className="bg-[#111827] border border-gray-800 p-8 rounded-3xl hover:border-amber-500/20 transition-all flex flex-col justify-between">
              <div>
                <div className="w-12 h-12 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mb-6">
                  <svg className="w-6 h-6 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
                <h4 className="text-xl font-bold text-white mb-2">Manpower & Payroll Calculations</h4>
                <p className="text-gray-400 text-sm leading-relaxed mb-6">
                  Track worker roles, allocate daily wages, log payouts, and run financial cash flow analyses. Compute accurate profit margins automatically by combining material logs and manpower payouts inside the provider panel.
                </p>
              </div>
              <ul className="text-xs text-gray-500 space-y-2 border-t border-gray-800/50 pt-4">
                <li className="flex items-center"><span className="w-1.5 h-1.5 bg-emerald-400 rounded-full mr-2"></span> Daily wage ledger & payment logs</li>
                <li className="flex items-center"><span className="w-1.5 h-1.5 bg-emerald-400 rounded-full mr-2"></span> Integrated profit margin calculations</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 relative px-6 overflow-hidden">
        <div className="absolute inset-0 bg-amber-500/5 blur-[100px] pointer-events-none"></div>
        <div className="max-w-5xl mx-auto bg-gradient-to-br from-[#111827] to-[#1F2937] border border-gray-800 rounded-3xl p-8 sm:p-12 text-center relative shadow-2xl">
          
          <div className="max-w-2xl mx-auto space-y-6">
            <h3 className="text-2xl sm:text-4xl font-black text-white leading-tight">
              Ready to Digitalize Your Construction Site Operations?
            </h3>
            <p className="text-gray-400 text-sm sm:text-base">
              BuildConnect is built to provide transparency, accuracy, and efficiency. Access the central administrator panel or download our mobile app to begin managing your projects.
            </p>
            
            <div className="pt-4 flex flex-col sm:flex-row items-center justify-center gap-4">
              <button 
                onClick={() => alert('App downloading initialized...')} 
                className="w-full sm:w-auto bg-amber-500 hover:bg-amber-600 text-black font-extrabold px-8 py-4 rounded-xl text-sm transition-all hover:scale-105"
              >
                Download Mobile App
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer id="about" className="bg-[#080B11] border-t border-gray-900 px-6 py-16 text-gray-500 text-xs sm:text-sm">
        <div className="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-4 gap-12">
          
          <div className="space-y-4">
            <div className="flex items-center space-x-3">
              <div className="bg-amber-500 p-2 rounded-lg">
                <svg className="w-4 h-4 text-black" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
              </div>
              <span className="text-base font-extrabold text-white tracking-tight">BuildConnect</span>
            </div>
            <p className="text-gray-400 text-xs leading-relaxed">
              Providing modern tools, materials transparency, and auditing ecosystems for the next-generation construction market.
            </p>
          </div>

          <div>
            <h4 className="text-white font-bold text-xs uppercase tracking-wider mb-4">Core Platform</h4>
            <ul className="space-y-2 text-xs">
              <li><a href="#simulator" className="hover:text-amber-500 transition-colors">Interactive Demo</a></li>
              <li><a href="#features" className="hover:text-amber-500 transition-colors">Key Modules</a></li>
              <li><a href="#problems" className="hover:text-amber-500 transition-colors">Market Obstacles</a></li>
            </ul>
          </div>

          <div>
            <h4 className="text-white font-bold text-xs uppercase tracking-wider mb-4">Support</h4>
            <ul className="space-y-2 text-xs">
              <li><a href="mailto:info@buildconnect.in" className="hover:text-amber-500 transition-colors">info@buildconnect.in</a></li>
              <li><a href="tel:+919986232326" className="hover:text-amber-500 transition-colors">+91 9986232326</a></li>
              <li><span className="text-gray-600">Mon - Sat: 9:00 AM - 6:00 PM</span></li>
            </ul>
          </div>

          <div>
            <h4 className="text-white font-bold text-xs uppercase tracking-wider mb-4">Office Location</h4>
            <p className="text-gray-400 text-xs leading-relaxed">
              #70, 9th Block NGEF Employee Layout, 2nd Stage,<br />
              Mallathahalli, Bangalore South,<br />
              Bangalore, Karnataka - 560056
            </p>
          </div>

        </div>

        <div className="max-w-7xl mx-auto mt-12 pt-8 border-t border-gray-900/60 flex flex-col sm:flex-row items-center justify-between text-xs text-gray-600">
          <p>© {new Date().getFullYear()} BuildConnect. All rights reserved.</p>
          <div className="flex space-x-6 mt-4 sm:mt-0">
            <span className="hover:text-amber-500 cursor-pointer">Privacy Policy</span>
            <span className="hover:text-amber-500 cursor-pointer">Terms of Service</span>
          </div>
        </div>
      </footer>

    </div>
  );
}
